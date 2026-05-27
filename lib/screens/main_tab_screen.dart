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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;

    String currentEffectiveMode = 'list';
    if (_selectedIndex == 1) {
      currentEffectiveMode = _containerLayoutMode;
    }

    final body = IndexedStack(
      index: _selectedIndex,
      children: [
        DashboardScreen(
          key: _dashboardKey,
          onSwitchToContainers: () {
            _containersKey.currentState?.refreshAfterSettings();
            _settingsKey.currentState?.refresh();
            _onItemTapped(1);
          },
          onSwitchToImages: () {
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
            _onItemTapped(0);
            NotifyUtils.showNotify(context, t.msgSettingsSaved);
          },
        ),
      ],
    );

    if (isWide) {
      return Scaffold(
        body: _buildWideLayout(body, t, currentEffectiveMode),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(_getTitle(t)),
        actions: _buildActions(t, currentEffectiveMode),
      ),
      body: body,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 0.5,
            color: colorScheme.outlineVariant,
          ),
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            animationDuration: const Duration(milliseconds: 400),
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            destinations: _buildDestinations(t),
          ),
        ],
      ),
      floatingActionButton: _selectedIndex != 1
          ? null
          : FloatingActionButton(
              onPressed: () {
                _containersKey.currentState?.showRunContainerDialog();
              },
              child: const Icon(Icons.add),
            ),
    );
  }

  List<Widget> _buildActions(AppLocalizations t, String currentEffectiveMode) {
    return [
      if (_selectedIndex == 1)
        IconButton(
          icon: Icon(currentEffectiveMode == 'grid'
              ? Icons.view_list
              : Icons.grid_view),
          onPressed: _toggleLayoutMode,
          tooltip: 'Switch Layout',
        ),
      if (_selectedIndex < 2)
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
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(width: 8),
    ];
  }

  Widget _buildWideLayout(Widget body, AppLocalizations t, String currentEffectiveMode) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          color: colorScheme.surface,
          child: NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.transparent,
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: const Icon(Icons.dashboard),
                label: Text(t.titleDashboard),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.dns_outlined),
                selectedIcon: const Icon(Icons.dns),
                label: Text(t.titleContainers),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.category_outlined),
                selectedIcon: const Icon(Icons.category),
                label: Text(t.titleResources),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: Text(t.titleSettings),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: colorScheme.outlineVariant),
        Expanded(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Divider(height: 1, color: colorScheme.outlineVariant),
                    Expanded(child: body),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 60,
                child: Container(
                  color: colorScheme.surface,
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getTitle(t),
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      ..._buildActions(t, currentEffectiveMode),
                    ],
                  ),
                ),
              ),
              if (_selectedIndex == 1)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    onPressed: () {
                      _containersKey.currentState?.showRunContainerDialog();
                    },
                    child: const Icon(Icons.add),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<NavigationDestination> _buildDestinations(AppLocalizations t) {
    return [
      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: t.titleDashboard,
      ),
      NavigationDestination(
        icon: const Icon(Icons.dns_outlined),
        selectedIcon: const Icon(Icons.dns),
        label: t.titleContainers,
      ),
      NavigationDestination(
        icon: const Icon(Icons.category_outlined),
        selectedIcon: const Icon(Icons.category),
        label: t.titleResources,
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: t.titleSettings,
      ),
    ];
  }
}
