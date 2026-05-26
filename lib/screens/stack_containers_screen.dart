import 'package:flutter/material.dart';
import 'package:mobile_portainer_flutter_module/services/platform/preferences_service.dart';
import 'package:mobile_portainer_flutter_module/l10n/app_localizations.dart';
import 'package:mobile_portainer_flutter_module/utils/notify_utils.dart';
import '../models/docker_container.dart';
import '../services/docker_service.dart';
import 'container_details_screen.dart';

class StackContainersScreen extends StatefulWidget {
  final String stackName;

  const StackContainersScreen({
    super.key,
    required this.stackName,
  });

  @override
  State<StackContainersScreen> createState() => StackContainersScreenState();
}

class StackContainersScreenState extends State<StackContainersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<DockerContainer> _allContainers = [];
  List<DockerContainer> _filteredContainers = [];
  bool _isLoading = false;
  String? _error;
  String _currentApiUrl = '';
  String _currentApiKey = '';
  bool _currentIgnoreSsl = false;
  bool _isCompactMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndFetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsAndFetch() async {
    final prefs = await PreferencesService.getInstance();
    final url = prefs.getString('docker_api_url') ?? 'http://10.0.2.2:2375';
    final apiKey = prefs.getString('docker_api_key') ?? '';
    final ignoreSsl = prefs.getString('docker_ignore_ssl') == 'true';
    if (mounted) {
      setState(() {
        _currentApiUrl = url;
        _currentApiKey = apiKey;
        _currentIgnoreSsl = ignoreSsl;
      });
      _fetchContainers();
    }
  }

  Future<void> _fetchContainers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final service = DockerService(
      baseUrl: _currentApiUrl,
      apiKey: _currentApiKey,
      ignoreSsl: _currentIgnoreSsl,
    );

    try {
      final containers = await service.getStackContainers(widget.stackName);
      
      if (mounted) {
        setState(() {
          _allContainers = containers;
          _filterContainers();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _allContainers = [];
          _filteredContainers = [];
        });
      }
    }
  }

  void _filterContainers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContainers = _allContainers.where((container) {
        return query.isEmpty || container.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    _filterContainers();
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

  Future<void> _deleteAllContainers() async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.titleConfirmDelete),
        content: Text(t.msgConfirmDeleteAllContainers),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t.actionDeleteAll),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      final service = DockerService(
        baseUrl: _currentApiUrl,
        apiKey: _currentApiKey,
        ignoreSsl: _currentIgnoreSsl,
      );

      final containersToDelete = List<DockerContainer>.from(_allContainers);
      int successCount = 0;
      int failCount = 0;

      for (final container in containersToDelete) {
        if (container.isSelf) continue;
        
        try {
          await service.removeContainer(container.id, force: true);
          successCount++;
        } catch (e) {
          debugPrint('Failed to delete container ${container.name}: $e');
          failCount++;
        }
      }

      if (mounted) {
        if (failCount > 0) {
          NotifyUtils.showNotify(context, 'Deleted $successCount, Failed $failCount');
        } else {
          NotifyUtils.showNotify(context, '$successCount containers deleted');
        }
        _fetchContainers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stackName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            onPressed: _allContainers.isEmpty ? null : _deleteAllContainers,
          ),
          IconButton(
            icon: Icon(
              _isCompactMode ? Icons.view_agenda_outlined : Icons.view_list,
            ),
            onPressed: () {
              setState(() {
                _isCompactMode = !_isCompactMode;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchContainers,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
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
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _filteredContainers.length,
                  itemBuilder: (context, index) {
                    final container = _filteredContainers[index];
                    if (_isCompactMode) {
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
                    return Card(
                      margin: const EdgeInsets.symmetric(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: _getStatusColor(
                                                container.status,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            container.status.toLowerCase(),
                                            style: TextStyle(
                                              color: _getStatusColor(
                                                container.status,
                                              ),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                              if (container.image.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  container.image,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (container.ports.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  container.ports,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
