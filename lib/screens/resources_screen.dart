import 'package:flutter/material.dart';
import 'package:mobile_portainer_flutter_module/l10n/app_localizations.dart';
import 'package:mobile_portainer_flutter_module/utils/notify_utils.dart';
import 'images_screen.dart';
import 'networks_screen.dart';
import 'stacks_screen.dart';
import 'volumes_screen.dart';
import 'env_vars_screen.dart';
import 'ports_screen.dart';
import 'image_details_screen.dart';
import 'network_details_screen.dart';
import 'stack_containers_screen.dart';
import 'volume_details_screen.dart';
import 'package:mobile_portainer_flutter_module/services/platform/preferences_service.dart';
import '../services/docker_service.dart';
import '../theme/app_theme.dart';
import '../widgets/resize_handle.dart';

class ResourcesScreen extends StatefulWidget {
  final Widget? bottomNavBar;

  const ResourcesScreen({super.key, this.bottomNavBar});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _imagesKey = GlobalKey<ImagesScreenState>();
  final _networksKey = GlobalKey<NetworksScreenState>();
  final _stacksKey = GlobalKey<StacksScreenState>();
  final _volumesKey = GlobalKey<VolumesScreenState>();

  String? _detailId;
  String? _detailName;
  int? _detailTab;
  double _splitRatio = 0.5;

  final _tabs = const [
    _TabDef(titleKey: 'titleImages', icon: Icons.layers, child: ImagesScreen()),
    _TabDef(titleKey: 'titleNetworks', icon: Icons.hub, child: NetworksScreen()),
    _TabDef(titleKey: 'titleStacks', icon: Icons.apps, child: StacksScreen()),
    _TabDef(titleKey: 'titleVolumes', icon: Icons.storage, child: VolumesScreen()),
    _TabDef(titleKey: 'titleEnvVars', icon: Icons.settings_ethernet, child: EnvVarsScreen()),
    _TabDef(titleKey: 'titlePorts', icon: Icons.settings_input_component, child: PortsScreen()),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      if (!_tabController.indexIsChanging) {
        if (_detailTab != null && _detailTab != _tabController.index) {
          _detailId = null;
          _detailName = null;
          _detailTab = null;
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWide = screenWidth / screenHeight > 18 / 16;

    if (isWide) {
      return _buildMasterDetail(t, colorScheme, screenWidth);
    }

    return Column(
      children: [
        Container(
          color: colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            tabs: _tabs.map((tab) {
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tab.icon, size: 18),
                    const SizedBox(width: 6),
                    Text(_titleFor(t, tab)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) => tab.child).toList(),
              ),
              if (_tabController.index == 0)
                Positioned(
                  right: 16,
                  bottom: AppTheme.fabBottomInset,
                  child: FloatingActionButton(
                    onPressed: () => _showPullImageDialog(context),
                    child: const Icon(Icons.add),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMasterDetail(AppLocalizations t, ColorScheme colorScheme, double totalWidth) {
    final tabIndex = _tabController.index;
    final hasSelection = _detailTab == tabIndex && _detailId != null;
    final leftFlex = (_splitRatio * 1000).round();
    final rightFlex = 1000 - leftFlex;

    Widget detailPanel;
    if (hasSelection) {
      switch (tabIndex) {
        case 0:
          final apiUrl = _imagesKey.currentState?.currentApiUrl ?? '';
          final apiKey = _imagesKey.currentState?.currentApiKey ?? '';
          final ignoreSsl = _imagesKey.currentState?.currentIgnoreSsl ?? false;
          detailPanel = ImageDetailsScreen(
            imageId: _detailId!,
            imageName: _detailName!,
            apiUrl: apiUrl,
            apiKey: apiKey,
            ignoreSsl: ignoreSsl,
          );
          break;
        case 1:
          final apiUrl = _networksKey.currentState?.currentApiUrl ?? '';
          final apiKey = _networksKey.currentState?.currentApiKey ?? '';
          final ignoreSsl = _networksKey.currentState?.currentIgnoreSsl ?? false;
          detailPanel = NetworkDetailsScreen(
            networkId: _detailId!,
            networkName: _detailName!,
            apiUrl: apiUrl,
            apiKey: apiKey,
            ignoreSsl: ignoreSsl,
          );
          break;
        case 2:
          detailPanel = StackContainersScreen(stackName: _detailName!);
          break;
        case 3:
          final apiUrl = _volumesKey.currentState?.currentApiUrl ?? '';
          final apiKey = _volumesKey.currentState?.currentApiKey ?? '';
          final ignoreSsl = _volumesKey.currentState?.currentIgnoreSsl ?? false;
          detailPanel = VolumeDetailsScreen(
            volumeName: _detailName!,
            apiUrl: apiUrl,
            apiKey: apiKey,
            ignoreSsl: ignoreSsl,
          );
          break;
        default:
          detailPanel = const SizedBox();
      }
    } else {
      detailPanel = const SizedBox();
    }

    return Row(
      children: [
        Expanded(
          flex: hasSelection ? leftFlex : 1,
          child: Column(
            children: [
              Container(
                color: colorScheme.surface,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  tabs: _tabs.map((tab) {
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tab.icon, size: 18),
                          const SizedBox(width: 6),
                          Text(_titleFor(t, tab)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    _buildActiveListScreen(),
                    if (widget.bottomNavBar != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: widget.bottomNavBar!,
                      ),
                    if (tabIndex == 0)
                      Positioned(
                        right: 16,
                        bottom: AppTheme.fabBottomInset,
                        child: FloatingActionButton(
                          onPressed: () => _showPullImageDialog(context),
                          child: const Icon(Icons.add),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (hasSelection) ...[
          ResizeHandle(
            totalWidth: totalWidth,
            onResized: (delta) {
              setState(() {
                _splitRatio = (_splitRatio + delta).clamp(0.2, 0.8);
              });
            },
          ),
          Expanded(
            flex: rightFlex,
            child: detailPanel,
          ),
        ],
      ],
    );
  }

  Widget _buildActiveListScreen() {
    final tabIndex = _tabController.index;
    final selectedId = _detailTab == tabIndex ? _detailId : null;
    switch (tabIndex) {
      case 0:
        return ImagesScreen(
          key: _imagesKey,
          onImageSelected: (id, name) => _onDetailSelected(0, id, name),
          selectedImageId: selectedId,
        );
      case 1:
        return NetworksScreen(
          key: _networksKey,
          onNetworkSelected: (id, name) => _onDetailSelected(1, id, name),
          selectedNetworkId: selectedId,
        );
      case 2:
        return StacksScreen(
          key: _stacksKey,
          onStackSelected: (name) => _onDetailSelected(2, name, name),
          selectedStackName: selectedId,
        );
      case 3:
        return VolumesScreen(
          key: _volumesKey,
          onVolumeSelected: (name) => _onDetailSelected(3, name, name),
          selectedVolumeName: selectedId,
        );
      default:
        return _tabs[tabIndex].child;
    }
  }

  void _onDetailSelected(int tab, String id, String name) {
    setState(() {
      if (_detailTab == tab && _detailId == id) {
        _detailId = null;
        _detailName = null;
        _detailTab = null;
      } else {
        _detailId = id;
        _detailName = name;
        _detailTab = tab;
      }
    });
  }

  String _titleFor(AppLocalizations t, _TabDef tab) {
    switch (tab.titleKey) {
      case 'titleImages': return t.titleImages;
      case 'titleNetworks': return t.titleNetworks;
      case 'titleStacks': return t.titleStacks;
      case 'titleVolumes': return t.titleVolumes;
      case 'titleEnvVars': return t.titleEnvVars;
      case 'titlePorts': return t.titlePorts;
      default: return tab.titleKey;
    }
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

class _TabDef {
  final String titleKey;
  final IconData icon;
  final Widget child;

  const _TabDef({
    required this.titleKey,
    required this.icon,
    required this.child,
  });
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
                  final index = _logs.indexWhere((log) => log['id'] == id);
                  if (index != -1) {
                    _logs[index] = {'id': id, 'message': message};
                  } else {
                    _logs.add({'id': id, 'message': message});
                  }
                } else {
                  _logs.add({'id': '', 'message': message});
                }

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
                        Navigator.pop(context);
                        if (context.mounted) {
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
