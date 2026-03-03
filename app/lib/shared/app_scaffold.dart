import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/analytics/screens/analytics_screen.dart';
import '../features/finder/screens/finder_screen.dart';
import '../features/social/screens/social_feed_screen.dart';
import '../features/discovery/screens/discovery_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/finder/providers/finder_tab_provider.dart';
import '../features/video_recipe/screens/video_recipe_screen.dart';

/// Tab indices used by [AppScaffold].
enum AppTab { discovery, social, videoRecipe, finder, history, analytics, settings }

/// Main app shell shown to authenticated users who have completed onboarding.
///
/// Holds top navigation state and swaps the body between tabs.
/// Features an adjustable sidebar mirroring the feel of an IDE.
class AppScaffold extends ConsumerStatefulWidget {
  const AppScaffold({super.key});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  AppTab _currentTab = AppTab.discovery;
  double _sidebarWidth = 250.0;
  bool _isSidebarVisible = true;

  @override
  Widget build(BuildContext context) {
    final currentFinderTab = ref.watch(finderTabProvider);

    return Scaffold(
      body: Row(
        children: [
          if (_isSidebarVisible) _buildSidebar(currentFinderTab),
          if (_isSidebarVisible)
            GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _sidebarWidth += details.delta.dx;
                  if (_sidebarWidth < 100) _sidebarWidth = 100;
                  if (_sidebarWidth > 500) _sidebarWidth = 500;
                });
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: Container(
                  width: 4,
                  color: Colors.grey[200],
                ),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                _buildTopNav(),
                const Divider(height: 1),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNav() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isSidebarVisible ? Icons.menu_open : Icons.menu),
            onPressed: () => setState(() => _isSidebarVisible = !_isSidebarVisible),
          ),
          const SizedBox(width: 8),
          const Text(
            'AllTogether',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Spacer(),
          ...AppTab.values.map((tab) => _buildNavButton(tab)),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=me'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(AppTab tab) {
    final isSelected = _currentTab == tab;
    final icon = switch (tab) {
      AppTab.discovery => Icons.explore_outlined,
      AppTab.social => Icons.people_outline,
      AppTab.videoRecipe => Icons.video_library_outlined,
      AppTab.finder => Icons.restaurant_menu_outlined,
      AppTab.history => Icons.receipt_long_outlined,
      AppTab.analytics => Icons.bar_chart_outlined,
      AppTab.settings => Icons.settings_outlined,
    };
    final selectedIcon = switch (tab) {
      AppTab.discovery => Icons.explore,
      AppTab.social => Icons.people,
      AppTab.videoRecipe => Icons.video_library,
      AppTab.finder => Icons.restaurant_menu,
      AppTab.history => Icons.receipt_long,
      AppTab.analytics => Icons.bar_chart,
      AppTab.settings => Icons.settings,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton.icon(
        icon: Icon(isSelected ? selectedIcon : icon, size: 18),
        style: TextButton.styleFrom(
          foregroundColor: isSelected ? Colors.green[700] : Colors.grey[600],
          backgroundColor: isSelected ? Colors.green[50] : Colors.transparent,
        ),
        onPressed: () => setState(() => _currentTab = tab),
        label: Text(
          tab.name[0].toUpperCase() + tab.name.substring(1),
          style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }

  Widget _buildSidebar(int currentFinderTab) {
    return Material(
      color: Colors.grey[50],
      child: Container(
        width: _sidebarWidth,
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'EXPLORER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            _buildSidebarItem(
              Icons.shopping_cart_outlined,
              'Shopping List',
              onTap: () {
                ref.read(finderTabProvider.notifier).state = 1;
                setState(() => _currentTab = AppTab.finder);
              },
              isSelected: _currentTab == AppTab.finder && currentFinderTab == 1,
            ),
            _buildSidebarItem(
              Icons.restaurant_outlined,
              'My Meals',
              onTap: () {
                ref.read(finderTabProvider.notifier).state = 0;
                setState(() => _currentTab = AppTab.finder);
              },
              isSelected: _currentTab == AppTab.finder && currentFinderTab == 0,
            ),
            _buildSidebarItem(
              Icons.eco_outlined,
              'Impact Stats',
              onTap: () => setState(() => _currentTab = AppTab.analytics),
              isSelected: _currentTab == AppTab.analytics,
            ),
            _buildSidebarItem(
              Icons.people_outline,
              'Following',
              onTap: () => setState(() => _currentTab = AppTab.social),
              isSelected: _currentTab == AppTab.social,
            ),
            const Spacer(),
            _buildSidebarItem(
              Icons.settings_outlined,
              'Settings',
              onTap: () => setState(() => _currentTab = AppTab.settings),
              isSelected: _currentTab == AppTab.settings,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title,
      {required VoidCallback onTap, bool isSelected = false}) {
    return ListTile(
      leading: Icon(icon, size: 20, color: isSelected ? Colors.green[700] : null),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.green[700] : null,
        ),
      ),
      dense: true,
      selected: isSelected,
      selectedTileColor: Colors.green[50],
      onTap: onTap,
    );
  }

  Widget _buildBody() {
    return switch (_currentTab) {
      AppTab.discovery => const DiscoveryScreen(),
      AppTab.social => const SocialFeedScreen(),
      AppTab.videoRecipe => const VideoRecipeScreen(),
      AppTab.finder => const FinderScreen(),
      AppTab.history => const HistoryScreen(),
      AppTab.analytics => const AnalyticsScreen(),
      AppTab.settings => const SettingsScreen(),
    };
  }
}

