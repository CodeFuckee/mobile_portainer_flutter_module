import 'package:flutter/material.dart';
import 'package:mobile_portainer_flutter_module/utils/notify_utils.dart';
import 'dart:async';
import 'package:mobile_portainer_flutter_module/services/platform/preferences_service.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../models/docker_container.dart';
import '../services/docker_service.dart';
import 'container_logs_screen.dart';
import 'container_details_screen.dart';
import 'package:mobile_portainer_flutter_module/l10n/app_localizations.dart';
import '../theme/theme_extensions.dart';

import '../widgets/env_vars_selector.dart';
import '../widgets/status_badge.dart';
import '../widgets/app_search_bar.dart';

import '../widgets/error_view.dart';
import '../widgets/empty_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/action_sheet.dart';

class HomeScreen extends StatefulWidget {
  final String layoutMode;

  const HomeScreen({
    super.key,
    this.layoutMode = 'grid',
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<DockerContainer> _allContainers = [];
  List<DockerContainer> _filteredContainers = [];
  String _selectedStatus = 'all';
  final List<String> _statusOptions = [
    'all',
    'running',
    'exited',
    'created',
    'restarting',
    'paused',
  ];
  String _selectedStack = 'all';
  List<String> _stackOptions = ['all'];
  bool _isLoading = false;
  String? _error;
  String _currentApiUrl = '';
  String _currentApiKey = '';
  bool _currentIgnoreSsl = false;
  WebSocketChannel? _eventChannel;
  Timer? _reconnectTimer;
  bool _isWsConnected = false;
  
  bool get _isCompactMode => widget.layoutMode == 'list';

  @override
  void initState() {
    super.initState();
    _loadSettingsAndFetch();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _eventChannel?.sink.close();
    super.dispose();
  }

  Future<void> _loadSettingsAndFetch() async {
    final prefs = await PreferencesService.getInstance();
    final url = prefs.getString('docker_api_url') ?? 'http://10.0.2.2:2375';
    final apiKey = prefs.getString('docker_api_key') ?? '';
    final ignoreSsl = prefs.getString('docker_ignore_ssl') == 'true';
    setState(() {
      _currentApiUrl = url;
      _currentApiKey = apiKey;
      _currentIgnoreSsl = ignoreSsl;
    });
    _fetchContainers();
    _connectWebSocket();
  }

  void refreshAfterSettings() {
    _loadSettingsAndFetch();
  }

  bool get isLoading => _isLoading;
  Future<void> manualRefresh() => _fetchContainers();
  bool get isWsConnected => _isWsConnected;

  Future<void> _fetchContainers({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final service = DockerService(
      baseUrl: _currentApiUrl,
      apiKey: _currentApiKey,
      ignoreSsl: _currentIgnoreSsl,
    );
    try {
      final containers = await service.getContainers();

      List<String> stacks = [];
      try {
        stacks = await service.getStacks();
      } catch (_) {
        // If API fails, fallback to extracting from containers
      }

      final allStacks = {
        ...stacks,
        ...containers.map((c) => c.stack).where((s) => s.isNotEmpty),
      }.toList()..sort();

      setState(() {
        _allContainers = containers;
        _stackOptions = ['all', ...allStacks];

        if (!_stackOptions.contains(_selectedStack)) {
          _selectedStack = 'all';
        }

        _filterContainers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _allContainers = [];
        _filteredContainers = [];
        _stackOptions = ['all'];
        _selectedStack = 'all';
      });
    }
  }

  Future<void> _connectWebSocket() async {
    _eventChannel?.sink.close();
    _reconnectTimer?.cancel();

    debugPrint('Connecting to WebSocket...');
    debugPrint('  API URL: $_currentApiUrl');
    debugPrint('  Ignore SSL: $_currentIgnoreSsl');

    final service = DockerService(
      baseUrl: _currentApiUrl,
      apiKey: _currentApiKey,
      ignoreSsl: _currentIgnoreSsl,
    );
    try {
      final channel = await service.connectToEvents();
      _eventChannel = channel;

      try {
        await channel.ready;
        if (mounted && _eventChannel == channel) {
          setState(() {
            _isWsConnected = true;
          });
        }
      } catch (e) {
        debugPrint('WebSocket connection failed (ready): $e');
        if (mounted && _eventChannel == channel) {
          _scheduleReconnect();
        }
        return;
      }

      channel.stream.listen(
        (message) {
          debugPrint('WebSocket received: $message');
          if (mounted && !_isWsConnected) {
            setState(() {
              _isWsConnected = true;
            });
          }
          _handleEvent(message);
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          if (_eventChannel != channel) return;

          setState(() {
            _isWsConnected = false;
          });
          if (_isAuthError(error)) {
            setState(() {
              _error = error.toString();
            });
            return;
          }
          _scheduleReconnect();
        },
        onDone: () async {
          debugPrint('WebSocket closed');
          if (_eventChannel != channel) return;

          setState(() {
            _isWsConnected = false;
          });
          // Wait for sink.done to ensure closeCode/closeReason are populated
          try {
            await channel.sink.done;
          } catch (e) {
            debugPrint('Wait for sink.done failed: $e');
          }

          if (_isAuthClose(channel)) {
            setState(() {
              _error = 'Authentication error (WebSocket closed)';
            });
            return;
          }
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!mounted) return;
    if (_reconnectTimer?.isActive ?? false) return;

    debugPrint('Scheduling WebSocket reconnection in 3 seconds...');
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _connectWebSocket();
      }
    });
  }

  bool _isAuthError(dynamic error) {
    final s = error?.toString().toLowerCase() ?? '';
    return s.contains('401') ||
        s.contains('403') ||
        s.contains('unauthorized') ||
        s.contains('invalid api key') ||
        s.contains('forbidden') ||
        s.contains('policy violation') ||
        s.contains('1008');
  }

  bool _isAuthClose(WebSocketChannel? channel) {
    final ch = channel ?? _eventChannel;
    if (ch is IOWebSocketChannel) {
      final code = ch.closeCode;
      final reason = ch.closeReason?.toLowerCase() ?? '';
      debugPrint('WebSocket Close Code: $code, Reason: $reason');
      
      if (code == 1008) return true;
      if (reason.contains('unauthorized') ||
          reason.contains('invalid api key') ||
          reason.contains('forbidden') ||
          reason.contains('policy violation')) {
        return true;
      }
    }
    return false;
  }

  void _handleEvent(dynamic message) {
    if (!mounted) return;
    try {
      final event = json.decode(message);
      debugPrint('Parsed event: $event');

      // Handle case-insensitive keys and old API format
      String? type = (event['Type'] ?? event['type'])?.toString().toLowerCase();
      String? action =
          (event['Action'] ?? event['action'] ?? event['status'])
              ?.toString()
              .toLowerCase();

      // Get ID from Actor or top-level
      String? containerId;
      dynamic actor = event['Actor'] ?? event['actor'];
      if (actor != null && actor is Map) {
        containerId = actor['ID'] ?? actor['id'];
      }
      containerId ??= event['id'] ?? event['Id'];

      if (type == 'container' && containerId != null && action != null) {
        debugPrint('Container event: $action for $containerId');

        if ([
          'start',
          'stop',
          'die',
          'pause',
          'unpause',
          'restart',
          'kill',
        ].contains(action)) {
          _updateContainerStatus(containerId, action);
        } else if (action == 'destroy') {
          _removeContainer(containerId);
        } else if (action == 'create') {
          _fetchContainers(silent: true);
        }
      }
    } catch (e) {
      debugPrint('Error parsing event: $e');
    }
  }

  void _removeContainer(String id) {
    if (!mounted) return;
    setState(() {
      _allContainers.removeWhere(
        (c) => id.startsWith(c.id) || c.id.startsWith(id),
      );
      _filterContainers();
    });
  }

  void _updateContainerStatus(String id, String action) {
    if (!mounted) return;
    debugPrint('Updating status for $id to $action');
    setState(() {
      // ID in event is full ID (64 chars), container.id might be short (12 chars) or full
      final index = _allContainers.indexWhere(
        (c) => id.startsWith(c.id) || c.id.startsWith(id),
      );

      if (index != -1) {
        debugPrint('Found container at index $index: ${_allContainers[index].name}');
        String newStatus = _allContainers[index].status;
        if (action == 'start' || action == 'unpause' || action == 'restart') {
          newStatus = 'running';
        } else if (action == 'stop' || action == 'die' || action == 'kill') {
          newStatus = 'exited';
        } else if (action == 'pause') {
          newStatus = 'paused';
        }

        _allContainers[index] = _allContainers[index].copyWith(
          status: newStatus,
        );
        _filterContainers();
      } else {
        debugPrint('Container $id not found in list');
      }
    });
  }

  void _filterContainers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContainers = _allContainers.where((container) {
        final matchesName =
            query.isEmpty || container.name.toLowerCase().contains(query);
        final matchesStatus =
            _selectedStatus == 'all' ||
            container.status.toLowerCase() == _selectedStatus;
        final matchesStack =
            _selectedStack == 'all' || container.stack == _selectedStack;
        return matchesName && matchesStatus && matchesStack;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    _filterContainers();
  }

  Color _getStatusColor(String status) {
    return StatusBadge.colorFor(status, Theme.of(context));
  }

  void _showFilterDialog() {
    final t = AppLocalizations.of(context)!;
    String tempStatus = _selectedStatus;
    String tempStack = _selectedStack;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(t.labelFilterStatus.replaceAll(":", "")),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.labelStatus,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: tempStatus,
                        isExpanded: true,
                        items: _statusOptions.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  status == 'all'
                                      ? t.labelStatusAll
                                      : status.toLowerCase(),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => tempStatus = value);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.labelStack,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: tempStack,
                        isExpanded: true,
                        items: _stackOptions.map((stack) {
                          return DropdownMenuItem(
                            value: stack,
                            child: Text(
                              stack == 'all' ? t.labelStatusAll : stack,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => tempStack = value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                  ), // Could be localized, but user didn't ask. Using system default usually? No, I should use text.
                ),
                ElevatedButton(
                  onPressed: () {
                    this.setState(() {
                      _selectedStatus = tempStatus;
                      _selectedStack = tempStack;
                      _filterContainers();
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showRunContainerDialog() {
    final t = AppLocalizations.of(context)!;
    final commandController = TextEditingController();
    bool isRunning = false;
    String? error;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(t.titleRunContainer),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: commandController,
                    decoration: InputDecoration(
                      labelText: t.labelCommand,
                      hintText: t.hintCommand,
                      errorText: error,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(t.actionInsertEnvVars),
                      onPressed: () async {
                        final List<Map<String, String>>? selectedVars = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EnvVarsSelector(),
                          ),
                        );
                        
                        if (selectedVars != null && selectedVars.isNotEmpty) {
                          final buffer = StringBuffer();
                          // Add space if needed
                          if (commandController.text.isNotEmpty && !commandController.text.endsWith(' ')) {
                            buffer.write(' ');
                          }
                          
                          for (var v in selectedVars) {
                            // Quote value if it contains spaces
                            String val = v['value'] ?? '';
                            if (val.contains(' ')) {
                              val = '"$val"';
                            }
                            buffer.write('-e ${v['key']}=$val ');
                          }
                          
                          final insertText = buffer.toString();
                          final currentText = commandController.text;
                          final selection = commandController.selection;
                          
                          String newText;
                          int newSelectionIndex;
                          
                          if (selection.isValid && selection.start >= 0) {
                             final start = selection.start;
                             newText = currentText.replaceRange(start, selection.end, insertText);
                             newSelectionIndex = start + insertText.length;
                          } else {
                             newText = currentText + insertText;
                             newSelectionIndex = newText.length;
                          }
                          
                          commandController.value = TextEditingValue(
                            text: newText,
                            selection: TextSelection.collapsed(offset: newSelectionIndex),
                          );
                        }
                      },
                    ),
                  ),
                  if (isRunning)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isRunning ? null : () => Navigator.pop(context),
                  child: Text(t.actionCancel),
                ),
                ElevatedButton(
                  onPressed: isRunning
                      ? null
                      : () async {
                          if (commandController.text.isEmpty) return;

                          setState(() {
                            isRunning = true;
                            error = null;
                          });

                          final service = DockerService(
                            baseUrl: _currentApiUrl,
                            apiKey: _currentApiKey,
                            ignoreSsl: _currentIgnoreSsl,
                          );

                          try {
                            final result = await service.runContainer(commandController.text);
                            if (context.mounted) {
                              Navigator.pop(context);
                              String msg = t.msgContainerStarted(result['name'] ?? result['short_id'] ?? result['id'] ?? 'unknown');
                              NotifyUtils.showNotify(context, msg);
                              _fetchContainers();
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                isRunning = false;
                                error = e.toString().replaceAll('Exception: ', '');
                              });
                            }
                          }
                        },
                  child: Text(t.actionRun),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatsBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    int running = 0, stopped = 0, paused = 0;
    for (final c in _allContainers) {
      switch (c.status) {
        case 'running': running++; break;
        case 'exited': stopped++; break;
        case 'paused': paused++; break;
      }
    }

    final filterChips = [
      ('running', Icons.play_circle_outline, running, StatusBadge.colorFor('running', theme)),
      ('exited', Icons.stop_circle_outlined, stopped, StatusBadge.colorFor('exited', theme)),
      ('paused', Icons.pause_circle_outline, paused, StatusBadge.colorFor('paused', theme)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Text(
              '${_allContainers.length} 个容器',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            ...filterChips.map((chip) {
              final (statusKey, icon, count, color) = chip;
              final isSelected = _selectedStatus == statusKey;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _selectedStatus = _selectedStatus == statusKey ? 'all' : statusKey;
                      _filterContainers();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.15)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? Border.all(color: color.withValues(alpha: 0.5))
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 14, color: color),
                          const SizedBox(width: 4),
                          Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? color : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final bool hasActiveFilters =
        _selectedStatus != 'all' || _selectedStack != 'all';

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        AppSearchBar(
          controller: _searchController,
          hintText: t.hintSearch,
          onChanged: _onSearchChanged,
          trailing: Material(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _showFilterDialog,
              child: Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: hasActiveFilters
                    ? BoxDecoration(
                        border: Border.all(color: colorScheme.primary, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      )
                    : null,
                child: Icon(
                  Icons.tune,
                  color: hasActiveFilters
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        if (!_isLoading && _error == null && _allContainers.isNotEmpty)
          _buildStatsBar(),
        if (_isLoading)
          const Expanded(child: LoadingView(type: LoadingType.list))
        else if (_error != null)
          Expanded(
            child: ErrorView(
              message: _error!,
              subtitle: t.msgCurrentApi(_currentApiUrl),
              onRetry: _fetchContainers,
              retryLabel: t.msgRetry,
            ),
          )
        else if (_filteredContainers.isEmpty)
          Expanded(
            child: EmptyView(
              icon: Icons.inbox_outlined,
              message: t.msgNoContainers,
            ),
          )
        else
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;
                
                if (isWide && !_isCompactMode) {
                  int crossAxisCount = constraints.maxWidth >= 900 ? 3 : 2;
                  return Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 190,
                      ),
                      itemCount: _filteredContainers.length,
                      itemBuilder: (context, index) {
                        return _buildContainerCard(
                          _filteredContainers[index],
                          t,
                          margin: EdgeInsets.zero,
                        );
                      },
                    ),
                  );
                }

                return Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _filteredContainers.length,
                    itemBuilder: (context, index) {
                      final container = _filteredContainers[index];
                      if (_isCompactMode) {
                        return _buildContainerTile(container, t);
                      }
                      return _buildContainerCard(container, t);
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showContainerActions(DockerContainer container) {
    final t = AppLocalizations.of(context)!;

    if (container.isSelf) {
      NotifyUtils.showNotify(context, t.msgOperationNotAllowed);
      return;
    }

    final dockerColors = Theme.of(context).extension<DockerColors>();

    // Define actions
    final actionStart = ActionItem(
      label: t.actionStart,
      icon: Icons.play_arrow,
      color: dockerColors?.statusRunning ?? Colors.green,
      actionCode: 'start',
    );
    final actionStop = ActionItem(
      label: t.actionStop,
      icon: Icons.stop,
      color: dockerColors?.statusExited ?? Colors.red,
      actionCode: 'stop',
    );
    final actionKill = ActionItem(
      label: t.actionKill,
      icon: Icons.dangerous,
      color: Colors.redAccent,
      actionCode: 'kill',
    );
    final actionRestart = ActionItem(
      label: t.actionRestart,
      icon: Icons.refresh,
      color: dockerColors?.statusCreated ?? Colors.blue,
      actionCode: 'restart',
    );
    final actionPause = ActionItem(
      label: t.actionPause,
      icon: Icons.pause,
      color: dockerColors?.statusRestarting ?? Colors.orange,
      actionCode: 'pause',
    );
    final actionResume = ActionItem(
      label: t.actionResume,
      icon: Icons.play_circle_outline,
      color: Colors.greenAccent,
      actionCode: 'resume',
    );
    final actionRemove = ActionItem(
      label: t.actionRemove,
      icon: Icons.delete,
      color: Colors.grey,
      actionCode: 'remove',
    );

    List<ActionItem> actions = [];

    // Filter actions based on status
    switch (container.status.toLowerCase()) {
      case 'running':
        actions = [
          actionStop,
          actionKill,
          actionRestart,
          actionPause,
          actionRemove,
        ];
        break;
      case 'exited':
      case 'stopped':
        actions = [actionStart, actionRemove, actionRestart];
        break;
      case 'paused':
        actions = [actionResume, actionRemove];
        break;
      case 'created':
        actions = [actionStart, actionRemove];
        break;
      case 'restarting':
        actions = [actionStop, actionKill, actionRemove];
        break;
      default:
        actions = [actionRemove];
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          container.status,
                        ).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.dns,
                        color: _getStatusColor(container.status),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            container.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Status: ${container.status}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Column(
                  children: actions
                      .map(
                        (action) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildActionButton(
                            action.label,
                            action.icon,
                            action.color,
                            () => _handleContainerAction(
                              container,
                              action.actionCode,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    // Use theme colors instead of specific action colors
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isDark ? Colors.white70 : Colors.black87,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContainerTile(DockerContainer container, AppLocalizations t) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(container.status);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ContainerDetailsScreen(
                  containerId: container.id,
                  containerName: container.name,
                  apiUrl: _currentApiUrl,
                  apiKey: _currentApiKey,
                  ignoreSsl: _currentIgnoreSsl,
                  isSelf: container.isSelf,
                ),
              ),
            );
          },
          onLongPress: () => _showContainerActions(container),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        container.name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (container.image.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          container.image,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: container.status, fontSize: 11),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContainerCard(
    DockerContainer container,
    AppLocalizations t, {
    EdgeInsetsGeometry? margin,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ContainerDetailsScreen(
                  containerId: container.id,
                  containerName: container.name,
                  apiUrl: _currentApiUrl,
                  apiKey: _currentApiKey,
                  ignoreSsl: _currentIgnoreSsl,
                  isSelf: container.isSelf,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        container.name.isNotEmpty
                            ? container.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            container.name,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          StatusBadge(status: container.status, fontSize: 11),
                        ],
                      ),
                    ),
                    _buildIconBtn(
                      Icons.article_outlined,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ContainerLogsScreen(
                              containerId: container.id,
                              containerName: container.name,
                              apiUrl: _currentApiUrl,
                              apiKey: _currentApiKey,
                              ignoreSsl: _currentIgnoreSsl,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 2),
                    _buildIconBtn(
                      Icons.more_vert,
                      () => _showContainerActions(container),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              const SizedBox(height: 10),
              if (container.stack.isNotEmpty)
                _buildInfoChip(Icons.layers_outlined, t.labelStack, container.stack),
              if (container.image.isNotEmpty)
                _buildInfoChip(Icons.image_outlined, t.labelImage, container.image),
              if (container.ports.isNotEmpty)
                _buildInfoChip(Icons.link, t.labelPorts, container.ports),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleContainerAction(
    DockerContainer container,
    String action,
  ) async {
    Navigator.pop(context); // Close bottom sheet

    setState(() {
      _isLoading = true;
    });

    final service = DockerService(
      baseUrl: _currentApiUrl,
      apiKey: _currentApiKey,
      ignoreSsl: _currentIgnoreSsl,
    );
    try {
      switch (action) {
        case 'start':
          await service.startContainer(container.id);
          break;
        case 'stop':
          await service.stopContainer(container.id);
          break;
        case 'kill':
          await service.killContainer(container.id);
          break;
        case 'restart':
          await service.restartContainer(container.id);
          break;
        case 'pause':
          await service.pauseContainer(container.id);
          break;
        case 'resume':
          await service.resumeContainer(container.id);
          break;
        case 'remove':
          await service.removeContainer(container.id);
          break;
      }

      if (mounted) {
        final t = AppLocalizations.of(context)!;
        String actionName = '';
        switch (action) {
          case 'start':
            actionName = t.actionStart;
            break;
          case 'stop':
            actionName = t.actionStop;
            break;
          case 'kill':
            actionName = t.actionKill;
            break;
          case 'restart':
            actionName = t.actionRestart;
            break;
          case 'pause':
            actionName = t.actionPause;
            break;
          case 'resume':
            actionName = t.actionResume;
            break;
          case 'remove':
            actionName = t.actionRemove;
            break;
        }

        NotifyUtils.showNotify(context, "${container.name}容器$actionName成功");
        // _fetchContainers(); // Removed as updates are handled via WebSocket
      }
    } catch (e) {
      if (mounted) {
        NotifyUtils.showNotify(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

}
