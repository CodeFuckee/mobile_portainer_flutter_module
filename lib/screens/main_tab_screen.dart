import 'package:flutter/material.dart';
import 'package:mobile_portainer_flutter_module/utils/notify_utils.dart';
import 'dashboard_screen.dart';
import 'home_screen.dart';
import 'images_screen.dart';
import 'resources_screen.dart';
import 'settings_screen.dart';
import 'package:mobile_portainer_flutter_module/l10n/app_localizations.dart';
import 'package:mobile_portainer_flutter_module/services/platform/preferences_service.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _selectedIndex = 0;
  bool _settingsChanged = false;
  // String _dashboardLayoutMode = 'auto'; // 'auto', 'list', 'grid' - Removed
  String _containerLayoutMode = 'grid'; // 'list', 'grid'

  final GlobalKey<DashboardScreenState> _dashboardKey =
      GlobalKey<DashboardScreenState>();
  final GlobalKey<HomeScreenState> _containersKey =
      GlobalKey<HomeScreenState>();
  final GlobalKey<ImagesScreenState> _imagesKey =
      GlobalKey<ImagesScreenState>();
  // Keys for other screens are no longer needed as they are navigated to from Resources
  final GlobalKey<SettingsScreenState> _settingsKey =
      GlobalKey<SettingsScreenState>();

  @override
  void initState() {
    super.initState();
    _loadLayoutPreference();
  }

  Future<void> _loadLayoutPreference() async {
    final prefs = await PreferencesService.getInstance();
    if (!mounted) return;
    setState(() {
      // _dashboardLayoutMode = prefs.getString('dashboard_layout_mode') ?? 'auto';
      _containerLayoutMode = prefs.getString('container_layout_mode') ?? 'grid';
    });
  }

  Future<void> _toggleLayoutMode() async {
    // final screenWidth = MediaQuery.of(context).size.width;
    final prefs = await PreferencesService.getInstance();
    // final isWide = screenWidth >= 600;

    if (_selectedIndex == 1) {
      // Container toggle
      // For containers, we only have 'grid' (normal) or 'list' (compact)
      // 'grid' means Card view (GridView on wide, Card List on narrow)
      // 'list' means Compact Tile view (List view always)
      String newMode = _containerLayoutMode == 'grid' ? 'list' : 'grid';
      
      await prefs.setString('container_layout_mode', newMode);
      
      if (!mounted) return;
      setState(() {
        _containerLayoutMode = newMode;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (_settingsChanged) {
      _dashboardKey.currentState?.refresh();
      _containersKey.currentState?.refreshAfterSettings();
      _imagesKey.currentState?.refreshAfterSettings();
      // Other screens will refresh when opened as they are pushed new
      _settingsChanged = false;
    }
    // Also refresh settings if we switch to it, to ensure it shows correct active server
    if (index == 3) {
      _settingsKey.currentState?.refresh();
    }
  }

  String _getTitle(AppLocalizations t) {
    switch (_selectedIndex) {
      case 0:
        return t.titleDashboard;
      case 1:
        return t.titleContainers;
      case 2:
        return t.titleResources;
      case 3:
        return t.titleSettings;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    // Calculate effective layout mode for UI display
    // final screenWidth = MediaQuery.of(context).size.width;
    // final isWide = screenWidth >= 600;
    
    String currentEffectiveMode = 'list';
    if (_selectedIndex == 1) {
      currentEffectiveMode = _containerLayoutMode;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(t)),
        actions: [
          if (_selectedIndex == 1) // Layout toggle for Containers
            IconButton(
              icon: Icon(currentEffectiveMode == 'grid' 
                  ? Icons.view_list 
                  : Icons.grid_view),
              onPressed: _toggleLayoutMode,
              tooltip: 'Switch Layout',
            ),
          if (_selectedIndex < 2) // Only Dashboard (0) and Containers (1) need refresh here
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                if (_selectedIndex == 0) {
                  _dashboardKey.currentState?.refresh();
                } else if (_selectedIndex == 1) {
                  if (_containersKey.currentState?.isLoading != true) {
                    _containersKey.currentState?.manualRefresh();
                  }
                }
              },
            ),
          const SizedBox(width: 4),
          Tooltip(
            message: (_containersKey.currentState?.isWsConnected ?? false)
                ? t.msgWsConnected
                : t.msgWsDisconnected,
            child: Icon(
              (_containersKey.currentState?.isWsConnected ?? false)
                  ? Icons.cloud_done
                  : Icons.cloud_off,
              color: (_containersKey.currentState?.isWsConnected ?? false)
                  ? Colors.green
                  : Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                _containersKey.currentState?.showRunContainerDialog();
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardScreen(
            key: _dashboardKey,
            onSwitchToContainers: () {
              // Refresh containers because server might have changed
              _containersKey.currentState?.refreshAfterSettings();
              _settingsKey.currentState?.refresh();
              _onItemTapped(1);
            },
            onSwitchToImages: () {
              // Switch to Resources tab (index 2) then open Images
              // This navigation is more complex now as Images is inside Resources
              // For now, let's just switch to Resources tab
              _settingsKey.currentState?.refresh();
              _onItemTapped(2);
            },
          ),
          HomeScreen(
            key: _containersKey,
            layoutMode: _containerLayoutMode,
          ),
          const ResourcesScreen(),
          SettingsScreen(
            key: _settingsKey,
            onSaved: () {
              _settingsChanged = true;
              // Go back to Dashboard and refresh
              _onItemTapped(0);
              NotifyUtils.showNotify(context, t.msgSettingsSaved);
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType
            .fixed, // Ensure all items are shown properly with 4 items
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: t.titleDashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.dns),
            label: t.titleContainers,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.category),
            label: t.titleResources,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: t.titleSettings,
          ),
        ],
      ),
    );
  }

  // Pull image dialog removed from main screen as Images screen is now nested.
  // It should be implemented inside ImagesScreen or ResourcesScreen if needed.
}
