import 'package:flutter/material.dart';
import 'package:mobile_portainer_flutter_module/services/platform/preferences_service.dart';
import 'package:intl/intl.dart';
import '../models/docker_image.dart';
import '../services/docker_service.dart';
import 'package:mobile_portainer_flutter_module/l10n/app_localizations.dart';
import 'package:mobile_portainer_flutter_module/utils/notify_utils.dart';
import 'image_details_screen.dart';

class ImagesScreen extends StatefulWidget {
  const ImagesScreen({super.key});

  @override
  State<ImagesScreen> createState() => ImagesScreenState();
}

class ImagesScreenState extends State<ImagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DockerImage> _allImages = [];
  List<DockerImage> _filteredImages = [];
  bool _isLoading = false;
  bool _isGridMode = true;
  String? _error;
  String _currentApiUrl = '';
  String _currentApiKey = '';
  bool _currentIgnoreSsl = false;
  final ScrollController _scrollController = ScrollController();

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
    final isGridMode = prefs.getBool('images_grid_mode') ?? true;
    
    if (mounted) {
      setState(() {
        _currentApiUrl = url;
        _currentApiKey = apiKey;
        _currentIgnoreSsl = ignoreSsl;
        _isGridMode = isGridMode;
      });
    }
    _fetchImages();
  }

  void refreshAfterSettings() {
    _loadSettingsAndFetch();
  }

  bool get isLoading => _isLoading;
  Future<void> manualRefresh() => _fetchImages();

  Future<void> _fetchImages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final service = DockerService(baseUrl: _currentApiUrl, apiKey: _currentApiKey, ignoreSsl: _currentIgnoreSsl);
    try {
      final images = await service.getImages();
      setState(() {
        _allImages = images;
        _filterImages();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _allImages = [];
        _filteredImages = [];
      });
    }
  }

  void _filterImages() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredImages = _allImages.where((image) {
        final tags = image.repoTags.join(', ').toLowerCase();
        final id = image.id.toLowerCase();
        return query.isEmpty || tags.contains(query) || id.contains(query);
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filterImages();
    });
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  Future<void> _confirmDelete(DockerImage image) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.titleConfirmDelete),
        content: Text(t.msgConfirmDeleteImage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t.actionDelete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteImage(image);
    }
  }

  Future<void> _deleteImage(DockerImage image) async {
    setState(() {
      _isLoading = true;
    });

    final service = DockerService(
      baseUrl: _currentApiUrl,
      apiKey: _currentApiKey,
      ignoreSsl: _currentIgnoreSsl,
    );
    try {
      final result = image.repoTags.isNotEmpty
          ? await service.deleteImage(image.repoTags.first)
          : await service.deleteImage(image.id);
      
      if (mounted) {
        String message = result['message'] ?? 'Image removed successfully';
        NotifyUtils.showNotify(context, message);
        _fetchImages();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        NotifyUtils.showNotify(context, 'Error: $e');
      }
    }
  }

  Future<void> _toggleLayoutMode() async {
    final prefs = await PreferencesService.getInstance();
    final newMode = !_isGridMode;
    await prefs.setBool('images_grid_mode', newMode);
    if (mounted) {
      setState(() {
        _isGridMode = newMode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
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
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                  onTap: _toggleLayoutMode,
                  child: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    child: Icon(
                      !_isGridMode
                          ? Icons.grid_view
                          : Icons.view_list,
                      color: Theme.of(context).iconTheme.color,
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
                      textAlign: TextAlign.center
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.msgCurrentApi(_currentApiUrl),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchImages,
                      child: Text(t.msgRetry),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (_filteredImages.isEmpty)
           Expanded(
            child: Center(
              child: Text(t.msgNoContainers.replaceAll('containers', 'images').replaceAll('容器', '镜像')), // Quick fallback, ideally add msgNoImages
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchImages,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  
                  if (isWide && _isGridMode) {
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
                          mainAxisExtent: 180,
                        ),
                        itemCount: _filteredImages.length,
                        itemBuilder: (context, index) {
                          final image = _filteredImages[index];
                          final tags = image.repoTags.isNotEmpty ? image.repoTags.join(', ') : '<none>';
                          String shortId = image.id;
                          if (shortId.startsWith('sha256:')) {
                             if (shortId.length > 7) {
                               shortId = shortId.substring(7);
                             }
                          }
                          if (shortId.length > 12) {
                            shortId = shortId.substring(0, 12);
                          }
                          return _buildImageCard(image, tags, shortId, t, margin: EdgeInsets.zero, isGrid: true);
                        },
                      ),
                    );
                  }

                  return Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _filteredImages.length,
                      itemBuilder: (context, index) {
                        final image = _filteredImages[index];
                        final tags = image.repoTags.isNotEmpty ? image.repoTags.join(', ') : '<none>';
                        String shortId = image.id;
                        if (shortId.startsWith('sha256:')) {
                           if (shortId.length > 7) {
                             shortId = shortId.substring(7);
                           }
                        }
                        if (shortId.length > 12) {
                          shortId = shortId.substring(0, 12);
                        }

                        if (!_isGridMode) {
                          return _buildImageTile(image, tags, shortId, t);
                        }
                        return _buildImageCard(image, tags, shortId, t);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageTile(DockerImage image, String tags, String shortId, AppLocalizations t) {
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
              builder: (context) => ImageDetailsScreen(
                imageId: image.id,
                imageName: tags,
                apiUrl: _currentApiUrl,
                apiKey: _currentApiKey,
                ignoreSsl: _currentIgnoreSsl,
              ),
            ),
          );
        },
        title: Text(
          tags,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image.inUse)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  t.labelInUse,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(image),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(DockerImage image, String tags, String shortId, AppLocalizations t, {EdgeInsetsGeometry? margin, bool isGrid = false}) {
    return Card(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageDetailsScreen(
                imageId: image.id,
                imageName: tags,
                apiUrl: _currentApiUrl,
                apiKey: _currentApiKey,
                ignoreSsl: _currentIgnoreSsl,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tags,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (image.inUse)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  border: Border.all(color: Colors.green),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  t.labelInUse,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () => _confirmDelete(image),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: $shortId',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isGrid) const Spacer() else const SizedBox(height: 12),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(Icons.data_usage, _formatSize(image.size)),
                  _buildInfoItem(Icons.access_time, _formatDate(image.created)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
