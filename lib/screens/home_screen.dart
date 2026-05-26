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

import '../widgets/env_vars_selector.dart';

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

    final service = DockerService(
      baseUrl: _currentApiUrl,
      apiKey: _currentApiKey,
      ignoreSsl: _currentIgnoreSsl,
    );
    try {
      debugPrint('Connecting to WebSocket...');
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
    setState(() {
      _filterContainers();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'running':
        return Colors.green;
      case 'exited':
        return Colors.red;
      case 'created':
        return Colors.blue;
      case 'restarting':
        return Colors.orange;
      case 'paused':
        return Colors.amber;
      default:
        return Colors.grey;
    }
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final bool hasActiveFilters =
        _selectedStatus != 'all' || _selectedStack != 'all';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: t.hintSearch,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(16.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16.0),
                  onTap: _showFilterDialog,
                  child: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: hasActiveFilters
                        ? BoxDecoration(
                            border: Border.all(color: Colors.blue, width: 2),
                            borderRadius: BorderRadius.circular(16.0),
                          )
                        : null,
                    child: Icon(
                      Icons.tune,
                      color: hasActiveFilters
                          ? Colors.blue
                          : Theme.of(context).iconTheme.color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.msgCurrentApi(_currentApiUrl),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchContainers,
                      child: Text(t.msgRetry),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (_filteredContainers.isEmpty)
          Expanded(child: Center(child: Text(t.msgNoContainers)))
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

    // Define actions
    final actionStart = _ActionItem(
      t.actionStart,
      Icons.play_arrow,
      Colors.green,
      'start',
    );
    final actionStop = _ActionItem(
      t.actionStop,
      Icons.stop,
      Colors.red,
      'stop',
    );
    final actionKill = _ActionItem(
      t.actionKill,
      Icons.dangerous,
      Colors.redAccent,
      'kill',
    );
    final actionRestart = _ActionItem(
      t.actionRestart,
      Icons.refresh,
      Colors.blue,
      'restart',
    );
    final actionPause = _ActionItem(
      t.actionPause,
      Icons.pause,
      Colors.orange,
      'pause',
    );
    final actionResume = _ActionItem(
      t.actionResume,
      Icons.play_circle_outline,
      Colors.greenAccent,
      'resume',
    );
    final actionRemove = _ActionItem(
      t.actionRemove,
      Icons.delete,
      Colors.grey,
      'remove',
    );

    List<_ActionItem> actions = [];

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
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 0,
        ),
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
        title: Text(
          container.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: _getStatusColor(
              container.status,
            ).withAlpha(30),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _getStatusColor(container.status),
            ),
          ),
          child: Text(
            container.status.toLowerCase(),
            style: TextStyle(
              color: _getStatusColor(container.status),
              fontSize: 12,
              fontWeight: FontWeight.bold,
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
    return Card(
      margin: margin ??
          const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            container.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                container.status,
                              ).withAlpha(30),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getStatusColor(container.status),
                              ),
                            ),
                            child: Text(
                              container.status.toLowerCase(),
                              style: TextStyle(
                                color: _getStatusColor(container.status),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.article_outlined),
                      tooltip: 'Logs',
                      onPressed: () {
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
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showContainerActions(container),
                    ),
                  ],
                ),
                const Divider(height: 16),
                if (container.stack.isNotEmpty) ...[
                  _buildInfoRow(t.labelStack, container.stack),
                  const SizedBox(height: 4),
                ],
                if (container.image.isNotEmpty) ...[
                  _buildInfoRow(t.labelImage, container.image),
                  const SizedBox(height: 4),
                ],
                if (container.ports.isNotEmpty) ...[
                  _buildInfoRow(t.labelPorts, container.ports),
                ],
              ],
            ),
          ),
        ),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final String actionCode;

  _ActionItem(this.label, this.icon, this.color, this.actionCode);
}
