import 'package:flutter/material.dart';
import 'package:mobile_portainer_flutter_module/screens/qr_scan_screen.dart';
import 'package:mobile_portainer_flutter_module/utils/notify_utils.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_portainer_flutter_module/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import '../main.dart';

import 'package:mobile_portainer_flutter_module/services/update_service.dart';
import '../services/harmonyos_platform.dart';
import '../services/harmonyos_shared_prefs.dart';
import '../utils/platform_detector.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onSaved;
  const SettingsScreen({super.key, this.onSaved});

  @override
  State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  String _currentLanguage = 'system';
  String _currentTimezone = 'system';
  String _versionText = '';
  
  // Server Management
  List<Map<String, String>> _servers = [];
  String? _activeApiUrl;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadVersion();
  }

  void refresh() {
    _loadSettings();
  }

  /// 获取偏好设置实例（兼容 Android 和鸿蒙）
  Future<dynamic> _getPrefs() async {
    if (PlatformDetector.isOhos) {
      return HarmonyosPreferences.getInstance();
    }
    return SharedPreferences.getInstance();
  }

  Future<void> _loadSettings() async {
    final prefs = await _getPrefs();
    final languageCode = await prefs.getString('language_code');
    final timezoneCode = await prefs.getString('timezone_code');
    final activeApiUrl = await prefs.getString('docker_api_url');
    final serverListJson = await prefs.getString('server_list');

    String? apiKey;
    if (serverListJson == null && activeApiUrl != null && activeApiUrl.isNotEmpty) {
      apiKey = await prefs.getString('docker_api_key');
    }

    setState(() {
      _currentLanguage = languageCode ?? 'system';
      _currentTimezone = timezoneCode ?? 'system';
      _activeApiUrl = activeApiUrl;

      if (serverListJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(serverListJson);
          _servers = decoded.map((e) => Map<String, String>.from(e)).toList();
        } catch (e) {
          debugPrint('Error parsing server list: $e');
          _servers = [];
        }
      }

      // Migration: If list is empty but we have an active URL, create a default entry
      if (_servers.isEmpty && _activeApiUrl != null && _activeApiUrl!.isNotEmpty) {
        _servers.add({
          'name': 'Default Server',
          'url': _activeApiUrl!,
          'apiKey': apiKey ?? '',
        });
        // defer saving to after setState
      }

      _isLoading = false;
    });

    // Save server list outside setState for migration case
    if (_servers.isNotEmpty && _servers.length == 1) {
      await _saveServerList(prefs);
    }
  }

  Future<void> _loadVersion() async {
    if (PlatformDetector.isOhos) {
      final info = await HarmonyosPlatform.getPackageInfo();
      if (!mounted) return;
      setState(() {
        _versionText = '${info['version']}+${info['buildNumber']}';
      });
      return;
    }
    final info = await PackageInfo.fromPlatform();
    if (!mounted) {
      return;
    }
    setState(() {
      _versionText = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _saveServerList(dynamic prefs) async {
    await prefs.setString('server_list', jsonEncode(_servers));
  }

  Future<void> _updateTimezone(String? newValue) async {
    if (newValue == null) return;
    setState(() {
      _currentTimezone = newValue;
    });
    final prefs = await _getPrefs();
    await prefs.setString('timezone_code', newValue);
    // Timezone usually affects display, so we might want to refresh lists too
    if (widget.onSaved != null) widget.onSaved!();
  }

  Future<void> _checkUpdate() async {
    await UpdateService.checkUpdate(context, showNoUpdateToast: true);
  }

  Future<void> _openGithub() async {
    final Uri url = Uri.parse('https://github.com/CodeFuckee/mobile_portainer_flutter_module');
    bool launched;
    if (PlatformDetector.isOhos) {
      launched = await HarmonyosPlatform.launchUrl(url.toString());
    } else {
      launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    if (!launched) {
      if (mounted) {
        NotifyUtils.showNotify(context, 'Could not launch GitHub');
      }
    }
  }

  void _onLanguageChanged(String? newValue) async {
    if (newValue == null) return;
    setState(() {
      _currentLanguage = newValue;
    });

    Locale? newLocale;
    if (newValue == 'en') {
      newLocale = const Locale('en');
    } else if (newValue == 'zh') {
      newLocale = const Locale('zh');
    }
    
    MyApp.setLocale(context, newLocale);
    
    // Language change persists in MyApp.setLocale logic (usually), 
    // but our main.dart handles it via SharedPreferences? 
    // Let's check main.dart if needed, but usually we should save it here too to be safe.
    final prefs = await _getPrefs();
    await prefs.setString('language_code', newValue);
  }

  Future<void> _switchServer(Map<String, String> server) async {
    final t = AppLocalizations.of(context)!;
    final prefs = await _getPrefs();
    await prefs.setString('docker_api_url', server['url']!);
    await prefs.setString('docker_api_key', server['apiKey'] ?? '');
    await prefs.setString('docker_ignore_ssl', server['ignoreSsl'] ?? 'false');
    
    setState(() {
      _activeApiUrl = server['url'];
    });
    
    if (mounted) {
      NotifyUtils.showNotify(context, t.msgServerSwitched(server['name']!));
    }
    
    if (widget.onSaved != null) {
        widget.onSaved!();
    }
  }

  Future<void> _copyServer(int index) async {
    final t = AppLocalizations.of(context)!;
    final server = _servers[index];
    
    final newServer = Map<String, String>.from(server);
    newServer['name'] = '${server['name']} - Copy';
    
    setState(() {
      _servers.add(newServer);
    });
    
    final prefs = await _getPrefs();
    await _saveServerList(prefs);
    
    if (mounted) {
      NotifyUtils.showNotify(context, t.msgServerCopied);
    }
  }

  Future<void> _deleteServer(int index) async {
    final server = _servers[index];
    final isDeletingActive = server['url'] == _activeApiUrl;
    
    setState(() {
      _servers.removeAt(index);
    });
    
    final prefs = await _getPrefs();
    await _saveServerList(prefs);
    
    if (isDeletingActive) {
      // If we deleted the active server, clear the active state or switch to another
      if (_servers.isNotEmpty) {
        _switchServer(_servers.first);
      } else {
        await prefs.remove('docker_api_url');
        await prefs.remove('docker_api_key');
        await prefs.remove('docker_ignore_ssl');
        setState(() {
          _activeApiUrl = null;
        });
      }
    }
    
    if (mounted) {
      final t = AppLocalizations.of(context)!;
      NotifyUtils.showNotify(context, t.msgServerDeleted);
    }
  }

  void _showAddServerOptions() {
    final t = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: Text(t.buttonScanQr),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QrScanScreen(),
                    ),
                  );
                  if (result != null && result is String && mounted) {
                     _processQrResult(result);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(t.buttonManualInput),
                onTap: () {
                  Navigator.pop(context);
                  _showServerDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _processQrResult(String result) {
    final t = AppLocalizations.of(context)!;
    try {
      final data = jsonDecode(result);
      if (data is Map) {
        String? url;
        String? apiKey;
        
        if (data.containsKey('url')) {
          url = data['url'];
        }
        if (data.containsKey('apikey')) {
          apiKey = data['apikey'];
        } else if (data.containsKey('apiKey')) {
          apiKey = data['apiKey'];
        }
        
        if (url != null || apiKey != null) {
          _showServerDialog(
            server: {
              'url': url ?? '',
              'apiKey': apiKey ?? '',
            },
            // Pass a flag or null index to indicate new server
          );
          NotifyUtils.showNotify(context, t.msgScanSuccess);
        }
      }
    } catch (e) {
      NotifyUtils.showNotify(context, t.msgInvalidQr);
    }
  }

  void _showServerDialog({Map<String, String>? server, int? index}) {
    final t = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: server?['name'] ?? '');
    final urlController = TextEditingController(text: server?['url'] ?? 'http://');
    final apiKeyController = TextEditingController(text: server?['apiKey'] ?? '');
    bool ignoreSsl = server?['ignoreSsl'] == 'true';
    bool isApiKeyVisible = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(server == null || index == null ? t.buttonAddServer : t.actionEdit),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: t.labelServerName,
                      hintText: 'My Home Server',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: t.labelDockerApiUrl,
                      hintText: t.hintIpPort,
                      helperText: t.helperDockerApiUrl,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: apiKeyController,
                    decoration: InputDecoration(
                      labelText: t.labelApiKey,
                      hintText: t.hintApiKey,
                      suffixIcon: IconButton(
                        icon: Icon(
                          isApiKeyVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            isApiKeyVisible = !isApiKeyVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !isApiKeyVisible,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(t.labelIgnoreSsl),
                    value: ignoreSsl,
                    onChanged: (bool value) {
                      setStateDialog(() {
                        ignoreSsl = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t.actionCancel),
              ),
              TextButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final url = urlController.text.trim();
                  final apiKey = apiKeyController.text.trim();
                  
                  if (name.isEmpty || url.isEmpty) {
                    // Simple validation
                    return;
                  }
                  
                  final newServer = {
                    'name': name,
                    'url': url,
                    'apiKey': apiKey,
                    'ignoreSsl': ignoreSsl.toString(),
                  };
                  
                  setState(() {
                    if (index != null) {
                      _servers[index] = newServer;
                      // If we edited the active server, update global prefs too
                      if (_activeApiUrl == server?['url']) {
                        _switchServer(newServer); 
                      }
                    } else {
                      _servers.add(newServer);
                      // If it's the first server, auto-switch to it
                      if (_servers.length == 1) {
                        _switchServer(newServer);
                      }
                    }
                  });
                  
                  final prefs = await _getPrefs();
                  await _saveServerList(prefs);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    NotifyUtils.showNotify(context, index != null ? t.msgServerUpdated : t.msgServerAdded);
                  }
                },
                child: Text(t.buttonSave),
              ),
            ],
          );
        },
      ),
    );
  }

  String _maskUrl(String url) {
    if (url.isEmpty) return '';
    try {
      final uri = Uri.parse(url);
      String host = uri.host;
      if (host.isEmpty) return url;
      
      String maskedHost = host;
      if (host.length > 5) {
        maskedHost = '${host.substring(0, 3)}****${host.substring(host.length - 2)}';
      } else {
        maskedHost = '****';
      }
      
      return url.replaceFirst(host, maskedHost);
    } catch (_) {
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // General Settings Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: t.labelLanguage,
                            border: const OutlineInputBorder(),
                          ),
                          value: _currentLanguage,
                          items: [
                            DropdownMenuItem(value: 'system', child: Text(t.optionSystem)),
                            DropdownMenuItem(value: 'en', child: Text(t.optionEnglish)),
                            DropdownMenuItem(value: 'zh', child: Text(t.optionChinese)),
                          ],
                          onChanged: _onLanguageChanged,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: t.labelTimezone,
                            border: const OutlineInputBorder(),
                          ),
                          value: _currentTimezone,
                          items: [
                            DropdownMenuItem(value: 'system', child: Text(t.optionSystem)),
                            DropdownMenuItem(value: 'utc', child: Text(t.optionUtc)),
                            DropdownMenuItem(value: 'utc+8', child: Text(t.optionUtcPlus8)),
                            DropdownMenuItem(value: 'utc+9', child: Text(t.optionUtcPlus9)),
                            DropdownMenuItem(value: 'utc-5', child: Text(t.optionUtcMinus5)),
                            DropdownMenuItem(value: 'utc+1', child: Text(t.optionUtcPlus1)),
                          ],
                          onChanged: _updateTimezone,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(t.actionUpdate),
                          leading: const Icon(Icons.system_update),
                          onTap: _checkUpdate,
                          trailing: const Icon(Icons.chevron_right),
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(t.labelGithub),
                          leading: const Icon(Icons.code),
                          onTap: _openGithub,
                          trailing: const Icon(Icons.open_in_new),
                        ),
                        if (_versionText.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'v$_versionText',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Servers Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t.sectionServers,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showAddServerOptions(),
                      tooltip: t.buttonAddServer,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Server List
                ..._servers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final server = entry.value;
                  final isActive = server['url'] == _activeApiUrl;
                  
                  return Card(
                    color: isActive ? Theme.of(context).colorScheme.primaryContainer : null,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(server['name'] ?? 'Unnamed'),
                      subtitle: Text(_maskUrl(server['url'] ?? '')),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isActive)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text(
                                  t.labelActive, 
                                  style: const TextStyle(fontSize: 10, height: 1.0) // Fix for small chips
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showServerDialog(server: server, index: index);
                              } else if (value == 'copy') {
                                _copyServer(index);
                              } else if (value == 'delete') {
                                _deleteServer(index);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(t.actionEdit),
                              ),
                              PopupMenuItem(
                                value: 'copy',
                                child: Text(t.actionCopy),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(t.actionDelete),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        if (!isActive) {
                          _switchServer(server);
                        }
                      },
                    ),
                  );
                }),
                
                if (_servers.isEmpty)
                   Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        t.buttonAddServer,
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
