import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_portainer_flutter_module/utils/notify_utils.dart';
import 'package:mobile_portainer_flutter_module/services/platform/preferences_service.dart';
import '../services/docker_service.dart';
import 'package:intl/intl.dart';
import '../widgets/section_title.dart';
import '../widgets/info_card.dart';
import '../widgets/info_row.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

class ImageDetailsScreen extends StatefulWidget {
  final String imageId;
  final String imageName; // RepoTags[0] or short ID
  final String apiUrl;
  final String apiKey;
  final bool ignoreSsl;

  const ImageDetailsScreen({
    super.key,
    required this.imageId,
    required this.imageName,
    required this.apiUrl,
    required this.apiKey,
    this.ignoreSsl = false,
  });

  @override
  State<ImageDetailsScreen> createState() => _ImageDetailsScreenState();
}

class _ImageDetailsScreenState extends State<ImageDetailsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _imageDetails;
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

    final service = DockerService(baseUrl: widget.apiUrl, apiKey: widget.apiKey, ignoreSsl: widget.ignoreSsl);
    try {
      final details = await service.getImage(widget.imageId);
      if (mounted) {
        setState(() {
          _imageDetails = details;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.imageName, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingView(type: LoadingType.card)
          : _error != null
              ? ErrorView(
                  message: _error!,
                  onRetry: _fetchDetails,
                  retryLabel: 'Retry',
                )
              : _buildDetailsList(),
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

  String _formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  Widget _buildDetailsList() {
    if (_imageDetails == null) return const SizedBox();

    final details = _imageDetails!;
    final config = details['Config'] ?? {};
    final rootFS = details['RootFS'] ?? {};
    final layers = rootFS['Layers'] as List? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionTitle('Basic Info'),
        _buildInfoCard([
          _buildInfoRow('ID', details['Id']?.toString().substring(7, 19) ?? '', showCopyButton: true), // Short ID
          _buildInfoRow('Full ID', details['Id']?.toString() ?? '', showCopyButton: true),
          _buildInfoRow('Size', _formatSize(details['Size'])),
          _buildInfoRow('Created', _formatDate(details['Created'])),
          _buildInfoRow('OS/Arch', '${details['Os']}/${details['Architecture']}'),
          _buildInfoRow('Docker Version', details['DockerVersion'] ?? ''),
          _buildInfoRow('Author', details['Author'] ?? ''),
        ]),
        const SizedBox(height: 16),

        if (details['RepoTags'] != null && (details['RepoTags'] as List).isNotEmpty) ...[
          _buildSectionTitle('Tags'),
          _buildListCard(details['RepoTags']),
          const SizedBox(height: 16),
        ],

        _buildSectionTitle('Config'),
        _buildInfoCard([
          _buildInfoRow('User', config['User'] ?? ''),
          _buildInfoRow('WorkingDir', config['WorkingDir'] ?? ''),
          _buildInfoRow('Entrypoint', (config['Entrypoint'] as List?)?.join(' ') ?? ''),
          _buildInfoRow('Cmd', (config['Cmd'] as List?)?.join(' ') ?? ''),
        ]),
        const SizedBox(height: 16),

        if (config['Env'] != null && (config['Env'] as List).isNotEmpty) ...[
          _buildSectionTitle('Environment Variables'),
          _buildEnvCard(config['Env']),
          const SizedBox(height: 16),
        ],

        if (config['Volumes'] != null && (config['Volumes'] as Map).isNotEmpty) ...[
          _buildSectionTitle('Volumes'),
          _buildMapCard(config['Volumes']),
          const SizedBox(height: 16),
        ],
        
        if (config['ExposedPorts'] != null && (config['ExposedPorts'] as Map).isNotEmpty) ...[
          _buildSectionTitle('Exposed Ports'),
          _buildMapCard(config['ExposedPorts']),
          const SizedBox(height: 16),
        ],

        if (config['Labels'] != null && (config['Labels'] as Map).isNotEmpty) ...[
          _buildSectionTitle('Labels'),
          _buildLabelsCard(config['Labels']),
          const SizedBox(height: 16),
        ],

        _buildSectionTitle('Layers (${layers.length})'),
        _buildListCard(layers.map((l) => l.toString()).toList(), monospace: true),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return SectionTitle(title: title);
  }

  Widget _buildInfoCard(List<Widget> children) {
    return InfoCard(children: children);
  }

  Widget _buildInfoRow(String label, String value, {bool showCopyButton = false}) {
    if (value.isEmpty) return const SizedBox.shrink();
    return InfoRow(
      label: label,
      value: value,
      showCopyButton: showCopyButton,
    );
  }

  Widget _buildListCard(List<dynamic> items, {bool monospace = false}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    item.toString(), 
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: monospace ? 'monospace' : null,
                    )
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
                  Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  SelectableText(value, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                  const Divider(),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMapCard(Map<String, dynamic> map) {
    List<Widget> widgets = [];
    map.forEach((key, value) {
       widgets.add(
         Padding(
           padding: const EdgeInsets.only(bottom: 8.0),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               SelectableText(key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
               if (value != null && value.toString() != '{}')
                  SelectableText(value.toString(), style: const TextStyle(fontSize: 13)),
               const Divider(),
             ],
           ),
         )
       );
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widgets,
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
              Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              SelectableText(value.toString(), style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
            ],
          ),
        )
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
}
