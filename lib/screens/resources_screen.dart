import 'package:flutter/material.dart';
import 'package:mobile_portainer_flutter_module/l10n/app_localizations.dart';
import 'package:mobile_portainer_flutter_module/utils/notify_utils.dart';
import 'images_screen.dart';
import 'networks_screen.dart';
import 'stacks_screen.dart';
import 'volumes_screen.dart';
import 'env_vars_screen.dart';
import 'ports_screen.dart';
import 'package:mobile_portainer_flutter_module/services/platform/preferences_service.dart';
import '../services/docker_service.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    final items = [
      _ResourceItem(
        title: t.titleImages,
        icon: Icons.layers,
        color: Colors.purple,
        screen: const ImagesScreen(),
        hasFab: true,
      ),
      _ResourceItem(
        title: t.titleNetworks,
        icon: Icons.hub,
        color: Colors.orange,
        screen: const NetworksScreen(),
      ),
      _ResourceItem(
        title: t.titleStacks,
        icon: Icons.apps,
        color: Colors.teal,
        screen: const StacksScreen(),
      ),
      _ResourceItem(
        title: t.titleVolumes,
        icon: Icons.storage,
        color: Colors.brown,
        screen: const VolumesScreen(),
      ),
      _ResourceItem(
        title: t.titleEnvVars,
        icon: Icons.settings_ethernet,
        color: Colors.blueGrey,
        screen: const EnvVarsScreen(),
      ),
      _ResourceItem(
        title: t.titlePorts,
        icon: Icons.settings_input_component,
        color: Colors.indigo,
        screen: const PortsScreen(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        if (isWide) {
          int crossAxisCount = constraints.maxWidth >= 900 ? 3 : 2;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildGridItem(context, items[index]);
            },
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildListItem(context, items[index]);
          },
        );
      },
    );
  }

  Widget _buildListItem(BuildContext context, _ResourceItem item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.icon, color: item.color, size: 28),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () => _navigateToScreen(context, item),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, _ResourceItem item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToScreen(context, item),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, _ResourceItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(item.title),
          ),
          body: item.screen,
          floatingActionButton: item.hasFab
              ? FloatingActionButton(
                  onPressed: () => _showPullImageDialog(context),
                  child: const Icon(Icons.add),
                )
              : null,
        ),
      ),
    );
  }

  Future<void> _showPullImageDialog(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final tagController = TextEditingController(text: 'latest');

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t.titlePullImage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: t.labelImageName,
                  hintText: t.hintImageName,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagController,
                decoration: InputDecoration(
                  labelText: t.labelTag,
                  hintText: t.hintTag,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t.actionCancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final tag = tagController.text.trim().isEmpty
                    ? 'latest'
                    : tagController.text.trim();
                Navigator.pop(dialogContext);
                if (name.isEmpty) {
                  NotifyUtils.showNotify(context, t.msgImageNameRequired);
                  return;
                }

                try {
                  final prefs = await PreferencesService.getInstance();
                  final url =
                      prefs.getString('docker_api_url') ??
                      'http://10.0.2.2:8000';
                  final apiKey = prefs.getString('docker_api_key') ?? '';
                  final ignoreSsl = prefs.getString('docker_ignore_ssl') == 'true';
                  
                  if (!context.mounted) return;

                  // Show progress dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => _PullProgressDialog(
                      name: name,
                      tag: tag,
                      baseUrl: url,
                      apiKey: apiKey,
                      ignoreSsl: ignoreSsl,
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  final errMsg = t.msgImagePullFailed(e.toString());
                  NotifyUtils.showNotify(context, errMsg);
                }
              },
              child: Text(t.buttonPull),
            ),
          ],
        );
      },
    );
  }
}

class _PullProgressDialog extends StatefulWidget {
  final String name;
  final String tag;
  final String baseUrl;
  final String apiKey;
  final bool ignoreSsl;

  const _PullProgressDialog({
    required this.name,
    required this.tag,
    required this.baseUrl,
    required this.apiKey,
    required this.ignoreSsl,
  });

  @override
  State<_PullProgressDialog> createState() => _PullProgressDialogState();
}

class _PullProgressDialogState extends State<_PullProgressDialog> {
  final List<Map<String, String>> _logs = [];
  final ScrollController _scrollController = ScrollController();
  late final DockerService _service;
  late final Stream<dynamic> _stream;
  bool _isDone = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _service = DockerService(
      baseUrl: widget.baseUrl,
      apiKey: widget.apiKey,
      ignoreSsl: widget.ignoreSsl,
    );
    _stream = _service.pullImageWs(widget.name, widget.tag);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    return AlertDialog(
      title: Text(t.titlePullImage),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: StreamBuilder<dynamic>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final data = snapshot.data;
              String id = '';
              String message = '';
              
              if (data is Map) {
                if (data.containsKey('error') || data.containsKey('errorDetail')) {
                   message = 'Error: ${data['error'] ?? data['errorDetail']?['message']}';
                   _hasError = true;
                } else {
                   final status = data['status'] ?? '';
                   id = data['id'] ?? '';
                   final progress = data['progress'] ?? '';
                   
                   if (id.isNotEmpty) {
                     message = '$id: $status $progress';
                   } else {
                     message = '$status $progress';
                   }
                }
              } else {
                message = data.toString();
              }
              
              if (message.trim().isNotEmpty) {
                if (id.isNotEmpty) {
                  // Check if we already have an entry for this ID
                  final index = _logs.indexWhere((log) => log['id'] == id);
                  if (index != -1) {
                    _logs[index] = {'id': id, 'message': message};
                  } else {
                    _logs.add({'id': id, 'message': message});
                  }
                } else {
                   // No ID, just append
                   _logs.add({'id': '', 'message': message});
                }
                
                // Auto scroll
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });
              }
            }
            
            if (snapshot.connectionState == ConnectionState.done) {
              if (!_isDone) {
                _isDone = true;
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                   if (mounted) {
                     setState(() {});
                     if (!_hasError) {
                        await Future.delayed(const Duration(seconds: 1));
                        if (mounted) {
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                          if(context.mounted){
                            NotifyUtils.showNotify(context, t.msgImagePullSuccess);
                          }
                        }
                      }
                   }
                });
              }
            }

            return ListView.builder(
              controller: _scrollController,
              itemCount: _logs.length + (_isDone && !_hasError ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _logs.length) {
                   return Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Text(
                       t.msgImagePullSuccess, 
                       style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                     ),
                   );
                }
                return Text(_logs[index]['message']!, style: const TextStyle(fontSize: 12));
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.actionCancel),
        ),
      ],
    );
  }
}

class _ResourceItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget screen;
  final bool hasFab;

  _ResourceItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.screen,
    this.hasFab = false,
  });
}
