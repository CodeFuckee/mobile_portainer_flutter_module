import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_portainer_flutter_module/utils/notify_utils.dart';
import 'package:mobile_portainer_flutter_module/services/platform/preferences_service.dart';
import '../services/docker_service.dart';
import 'package:intl/intl.dart';
import 'package:mobile_portainer_flutter_module/l10n/app_localizations.dart';
import '../theme/theme_extensions.dart';
import '../widgets/section_title.dart';
import '../widgets/info_card.dart';
import '../widgets/info_row.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/action_sheet.dart';
import 'container_logs_screen.dart';
import 'volume_details_screen.dart';
import 'container_files_screen.dart';
import 'image_details_screen.dart';
import 'network_details_screen.dart';

class ContainerDetailsScreen extends StatefulWidget {
  final String containerId;
  final String containerName;
  final String apiUrl;
  final String apiKey;
  final bool isSelf;
  final bool ignoreSsl;

  const ContainerDetailsScreen({
    super.key,
    required this.containerId,
    required this.containerName,
    required this.apiUrl,
    required this.apiKey,
    this.isSelf = false,
    this.ignoreSsl = false,
  });

  @override
  State<ContainerDetailsScreen> createState() => _ContainerDetailsScreenState();
}

class _ContainerDetailsScreenState extends State<ContainerDetailsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _containerDetails;
  String _timezoneCode = 'system';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchDetails();
  }

  Future<void> _loadPreferences() async {
    final prefs = await PreferencesService.getInstance();
    if (mounted) {
      setState(() {
        _timezoneCode = prefs.getString('timezone_code') ?? 'system';
      });
    }
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final service = DockerService(
      baseUrl: widget.apiUrl,
      apiKey: widget.apiKey,
      ignoreSsl: widget.ignoreSsl,
    );
    try {
      final details = await service.getContainer(widget.containerId);
      if (mounted) {
        setState(() {
          _containerDetails = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.containerName),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: t.tabOverview),
              Tab(text: t.tabLogs),
              Tab(text: t.tabFiles),
              Tab(text: t.tabNetwork),
              Tab(text: t.tabStorage),
              Tab(text: t.tabEnv),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchDetails,
            ),
            if (!_isLoading && _containerDetails != null)
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: _showActions,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
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
                        onPressed: _fetchDetails,
                        child: Text(t.msgRetry),
                      ),
                    ],
                  ),
                ),
              )
            : TabBarView(
                children: [
                  _buildOverviewTab(),
                  ContainerLogsScreen(
                    containerId: widget.containerId,
                    containerName: widget.containerName,
                    apiUrl: widget.apiUrl,
                    apiKey: widget.apiKey,
                    isEmbedded: true,
                    ignoreSsl: widget.ignoreSsl,
                  ),
                  ContainerFilesScreen(
                    containerId: widget.containerId,
                    containerName: widget.containerName,
                    apiUrl: widget.apiUrl,
                    apiKey: widget.apiKey,
                    ignoreSsl: widget.ignoreSsl,
                    isRunning: _containerDetails?['State']?['Running'] ?? false,
                  ),
                  _buildNetworkTab(),
                  _buildStorageTab(),
                  _buildEnvTab(),
                ],
              ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    if (dateStr == '0001-01-01T00:00:00Z') return '';
    try {
      DateTime date = DateTime.parse(dateStr);

      // Apply timezone adjustment
      switch (_timezoneCode) {
        case 'utc':
          date = date.toUtc();
          break;
        case 'utc+8':
          date = date.toUtc().add(const Duration(hours: 8));
          break;
        case 'utc+9':
          date = date.toUtc().add(const Duration(hours: 9));
          break;
        case 'utc-5':
          date = date.toUtc().subtract(const Duration(hours: 5));
          break;
        case 'utc+1':
          date = date.toUtc().add(const Duration(hours: 1));
          break;
        case 'system':
        default:
          date = date.toLocal();
          break;
      }

      return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildQuickActions() {
    if (_containerDetails == null || widget.isSelf) return const SizedBox();

    final actions = _getAvailableActions();
    if (actions.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          return _buildActionTile(actions[index]);
        },
      ),
    );
  }

  Widget _buildActionTile(_ActionItem action) {
    return Container(
      decoration: BoxDecoration(
        color: action.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: action.color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _performAction(action.actionCode),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(action.icon, color: action.color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                style: TextStyle(
                  color: action.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_containerDetails == null) return const SizedBox();

    final details = _containerDetails!;
    final state = details['State'] ?? {};
    final config = details['Config'] ?? {};
    final hostConfig = details['HostConfig'] ?? {};

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildQuickActions(),
        _buildSectionTitle('Basic Info'),
        _buildInfoCard([
          _buildInfoRow(
            'Name',
            details['Name']?.toString().replaceAll('/', '') ?? '',
            showCopyButton: true,
          ),
          _buildInfoRow(
            'ID',
            details['Id']?.toString().substring(0, 12) ?? '',
            showCopyButton: true,
            copyValue: details['Id']?.toString() ?? '',
          ),
          _buildInfoRow(
            'Image',
            config['Image'] ?? '',
            onTap: (config['Image'] != null && config['Image'].toString().isNotEmpty)
                ? () {
                    final imageId = details['Image']?.toString() ?? '';
                    final imageName = config['Image']?.toString() ?? imageId;
                    if (imageName.isEmpty && imageId.isEmpty) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageDetailsScreen(
                          imageId: imageId.isNotEmpty ? imageId : imageName,
                          imageName: imageName,
                          apiUrl: widget.apiUrl,
                          apiKey: widget.apiKey,
                          ignoreSsl: widget.ignoreSsl,
                        ),
                      ),
                    );
                  }
                : null,
          ),
          _buildInfoRow('Hostname', config['Hostname'] ?? ''),
          _buildInfoRow('Driver', details['Driver'] ?? ''),
          _buildInfoRow('Created', _formatDate(details['Created'])),
          _buildInfoRow('Platform', details['Platform'] ?? ''),
          _buildInfoRow(
            'Restart Count',
            details['RestartCount']?.toString() ?? '0',
          ),
        ]),
        const SizedBox(height: 16),
        _buildSectionTitle('State'),
        _buildInfoCard([
          _buildInfoRow('Status', state['Status'] ?? ''),
          _buildInfoRow('Running', state['Running']?.toString() ?? ''),
          _buildInfoRow('PID', state['Pid']?.toString() ?? ''),
          _buildInfoRow('OOM Killed', state['OOMKilled']?.toString() ?? ''),
          _buildInfoRow('Started At', _formatDate(state['StartedAt'])),
          if (state['FinishedAt'] != null &&
              state['FinishedAt'] != '0001-01-01T00:00:00Z')
            _buildInfoRow('Finished At', _formatDate(state['FinishedAt'])),
          if (state['ExitCode'] != null && state['ExitCode'] != 0)
            _buildInfoRow('Exit Code', state['ExitCode'].toString()),
          if (state['Error'] != null && state['Error'].toString().isNotEmpty)
            _buildInfoRow('Error', state['Error'].toString(), isError: true),
        ]),
        const SizedBox(height: 16),
        _buildSectionTitle('Host Config'),
        _buildInfoCard([
          _buildInfoRow('Runtime', hostConfig['Runtime'] ?? ''),
          _buildInfoRow(
            'Privileged',
            hostConfig['Privileged']?.toString() ?? 'false',
          ),
          _buildInfoRow(
            'Restart Policy',
            hostConfig['RestartPolicy']?['Name'] ?? '',
          ),
          _buildInfoRow(
            'Auto Remove',
            hostConfig['AutoRemove']?.toString() ?? 'false',
          ),
        ]),
      ],
    );
  }

  Widget _buildNetworkTab() {
    if (_containerDetails == null) return const SizedBox();
    final details = _containerDetails!;
    final networkSettings = details['NetworkSettings'] ?? {};

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ..._buildNetworkWidgets(networkSettings),
        if (networkSettings['Ports'] != null &&
            (networkSettings['Ports'] as Map).isNotEmpty) ...[
          _buildSectionTitle('Ports'),
          _buildPortsCard(networkSettings['Ports']),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildStorageTab() {
    if (_containerDetails == null) return const SizedBox();
    final details = _containerDetails!;
    final config = details['Config'] ?? {};

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (details['Mounts'] != null &&
            (details['Mounts'] as List).isNotEmpty) ...[
          _buildSectionTitle('Mounts'),
          _buildMountsCard(details['Mounts']),
          const SizedBox(height: 16),
        ],
        if (config['Volumes'] != null &&
            (config['Volumes'] as Map).isNotEmpty) ...[
          _buildSectionTitle('Configured Volumes'),
          _buildVolumesCard(config['Volumes']),
          const SizedBox(height: 16),
        ] else if ((details['Mounts'] == null ||
            (details['Mounts'] as List).isEmpty)) ...[
          const Center(
            child: Text(
              "No storage configuration found.",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEnvTab() {
    if (_containerDetails == null) return const SizedBox();
    final details = _containerDetails!;
    final config = details['Config'] ?? {};

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionTitle('Command & Execution'),
        _buildInfoCard([
          _buildInfoRow('WorkDir', config['WorkingDir'] ?? ''),
          _buildInfoRow(
            'Entrypoint',
            (config['Entrypoint'] as List?)?.join(' ') ?? '',
          ),
          _buildInfoRow('Cmd', (config['Cmd'] as List?)?.join(' ') ?? ''),
          _buildInfoRow(
            'User',
            (config['User'] == null || config['User'].isEmpty)
                ? 'root'
                : config['User'],
          ),
        ]),
        const SizedBox(height: 16),
        if (config['Env'] != null && (config['Env'] as List).isNotEmpty) ...[
          _buildSectionTitle('Environment Variables'),
          _buildEnvCard(config['Env']),
          const SizedBox(height: 16),
        ],
        if (config['Labels'] != null &&
            (config['Labels'] as Map).isNotEmpty) ...[
          _buildSectionTitle('Labels'),
          _buildLabelsCard(config['Labels']),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return SectionTitle(title: title);
  }

  Widget _buildInfoCard(List<Widget> children) {
    return InfoCard(children: children);
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isError = false,
    VoidCallback? onTap,
    bool showCopyButton = false,
    String? copyValue,
  }) {
    return InfoRow(
      label: label,
      value: value,
      isError: isError,
      onTap: onTap,
      showCopyButton: showCopyButton,
      copyValue: copyValue,
    );
  }

  Widget _buildPortsCard(Map<String, dynamic> ports) {
    List<Widget> portWidgets = [];
    ports.forEach((key, value) {
      String mappings = '';
      if (value != null && value is List) {
        mappings = value
            .map((m) => "${m['HostIp']}:${m['HostPort']}")
            .join(', ');
      }
      portWidgets.add(
        _buildInfoRow(key, mappings.isEmpty ? 'Not mapped' : mappings),
      );
    });

    return _buildInfoCard(portWidgets);
  }

  Widget _buildEnvCard(List<dynamic> envs) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: envs.map((env) {
            final parts = env.toString().split('=');
            final key = parts.isNotEmpty ? parts[0] : '';
            final value = parts.length > 1 ? parts.sublist(1).join('=') : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  SelectableText(
                    value,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                  const Divider(),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMountsCard(List<dynamic> mounts) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: mounts.map((mount) {
            final isVolume = mount['Type'] == 'volume';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Type', mount['Type'] ?? ''),
                  if (mount['Name'] != null)
                    _buildInfoRow(
                      'Name',
                      mount['Name'],
                      onTap: isVolume
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VolumeDetailsScreen(
                                    volumeName: mount['Name'],
                                    apiUrl: widget.apiUrl,
                                    apiKey: widget.apiKey,
                                    ignoreSsl: widget.ignoreSsl,
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                  _buildInfoRow('Source', mount['Source'] ?? ''),
                  _buildInfoRow('Destination', mount['Destination'] ?? ''),
                  if (mount['Mode'] != null &&
                      mount['Mode'].toString().isNotEmpty)
                    _buildInfoRow('Mode', mount['Mode']),
                  _buildInfoRow('RW', (mount['RW'] == true).toString()),
                  const Divider(),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildVolumesCard(Map<String, dynamic> volumes) {
    List<Widget> volumeWidgets = [];
    volumes.forEach((key, value) {
      volumeWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Volume',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              SelectableText(key, style: const TextStyle(fontSize: 13)),
              const Divider(),
            ],
          ),
        ),
      );
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: volumeWidgets,
        ),
      ),
    );
  }

  Widget _buildLabelsCard(Map<String, dynamic> labels) {
    List<Widget> labelWidgets = [];
    labels.forEach((key, value) {
      labelWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                key,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              SelectableText(
                value.toString(),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      );
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: labelWidgets,
        ),
      ),
    );
  }

  List<Widget> _buildNetworkWidgets(Map<String, dynamic> networkSettings) {
    List<Widget> widgets = [];
    final networks = networkSettings['Networks'];

    if (networks is Map && networks.isNotEmpty) {
      networks.forEach((name, data) {
        if (data is Map) {
          widgets.add(_buildSectionTitle('Network: $name'));
          widgets.add(
            _buildInfoCard([
              _buildInfoRow(
                'Name',
                name,
                onTap: () {
                  final netId = (data['NetworkID'] ?? '').toString();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NetworkDetailsScreen(
                        networkId: netId.isNotEmpty ? netId : name,
                        networkName: name,
                        apiUrl: widget.apiUrl,
                        apiKey: widget.apiKey,
                        ignoreSsl: widget.ignoreSsl,
                      ),
                    ),
                  );
                },
              ),
              _buildInfoRow('IP Address', data['IPAddress'] ?? ''),
              _buildInfoRow('Gateway', data['Gateway'] ?? ''),
              _buildInfoRow('Mac Address', data['MacAddress'] ?? ''),
              if (data['NetworkID'] != null &&
                  data['NetworkID'].toString().isNotEmpty)
                _buildInfoRow(
                  'Network ID',
                  data['NetworkID'].toString().substring(0, 12),
                  showCopyButton: true,
                  copyValue: data['NetworkID'].toString(),
                  onTap: () {
                    final netId = data['NetworkID'].toString();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NetworkDetailsScreen(
                          networkId: netId,
                          networkName: name,
                          apiUrl: widget.apiUrl,
                          apiKey: widget.apiKey,
                          ignoreSsl: widget.ignoreSsl,
                        ),
                      ),
                    );
                  },
                ),
            ]),
          );
          widgets.add(const SizedBox(height: 16));
        }
      });
    } else {
      widgets.add(_buildSectionTitle('Network'));
      widgets.add(
        _buildInfoCard([
          _buildInfoRow('IP Address', networkSettings['IPAddress'] ?? ''),
          _buildInfoRow('Gateway', networkSettings['Gateway'] ?? ''),
          _buildInfoRow('Mac Address', networkSettings['MacAddress'] ?? ''),
        ]),
      );
      widgets.add(const SizedBox(height: 16));
    }
    return widgets;
  }

  List<_ActionItem> _getAvailableActions() {
    if (_containerDetails == null) return [];
    final t = AppLocalizations.of(context)!;
    final state = _containerDetails!['State'] ?? {};
    final status = (state['Status'] ?? '').toString().toLowerCase();

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
    if (status.contains('running')) {
      actions = [
        actionStop,
        actionKill,
        actionRestart,
        actionPause,
        actionRemove,
      ];
    } else if (status.contains('exited') || status.contains('stopped')) {
      actions = [actionStart, actionRemove, actionRestart];
    } else if (status.contains('paused')) {
      actions = [actionResume, actionRemove];
    } else if (status.contains('created')) {
      actions = [actionStart, actionRemove];
    } else if (status.contains('restarting')) {
      actions = [actionStop, actionKill, actionRemove];
    } else {
      actions = [actionRemove];
    }
    return actions;
  }

  void _showActions() {
    if (_containerDetails == null) return;
    final t = AppLocalizations.of(context)!;

    if (widget.isSelf) {
      NotifyUtils.showNotify(context, t.msgOperationNotAllowed);
      return;
    }

    final actions = _getAvailableActions();

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
                Column(
                  children: actions
                      .map(
                        (action) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildActionButton(
                            action.label,
                            action.icon,
                            action.color,
                            () {
                              Navigator.pop(context); // Close bottom sheet
                              _performAction(action.actionCode);
                            },
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

  Future<void> _performAction(String action) async {
    // Navigator.pop(context); // Handled by caller if needed

    setState(() {
      _isLoading = true;
    });

    final service = DockerService(
      baseUrl: widget.apiUrl,
      apiKey: widget.apiKey,
      ignoreSsl: widget.ignoreSsl,
    );
    try {
      switch (action) {
        case 'start':
          await service.startContainer(widget.containerId);
          break;
        case 'stop':
          await service.stopContainer(widget.containerId);
          break;
        case 'kill':
          await service.killContainer(widget.containerId);
          break;
        case 'restart':
          await service.restartContainer(widget.containerId);
          break;
        case 'pause':
          await service.pauseContainer(widget.containerId);
          break;
        case 'resume':
          await service.resumeContainer(widget.containerId);
          break;
        case 'remove':
          await service.removeContainer(widget.containerId);
          if (mounted) Navigator.pop(context); // Go back to home if removed
          return;
      }

      if (mounted) {
        // Simple success message
        final t = AppLocalizations.of(context)!;
        String actionName = action;
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

        String msg = "${widget.containerName} $actionName success";
        NotifyUtils.showNotify(context, msg);
        _fetchDetails(); // Reload details
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        NotifyUtils.showNotify(context, 'Error: $e');
      }
    }
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final String actionCode;

  _ActionItem(this.label, this.icon, this.color, this.actionCode);
}
