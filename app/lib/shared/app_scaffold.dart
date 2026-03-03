import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/analytics/screens/analytics_screen.dart';
import '../features/finder/screens/finder_screen.dart';
import '../features/social/screens/social_feed_screen.dart';
import '../features/discovery/screens/discovery_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/finder/providers/finder_tab_provider.dart';
import '../features/video_recipe/screens/video_recipe_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/recipe_scraper/screens/recipe_scraper_screen.dart';

/// Tab indices used by [AppScaffold].
enum AppTab { potluck, whatsCookin, kaleculations, settings }

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
  AppTab _currentTab = AppTab.potluck;
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
      AppTab.potluck => Icons.groups_outlined,
      AppTab.whatsCookin => Icons.restaurant_menu_outlined,
      AppTab.kaleculations => Icons.analytics_outlined,
      AppTab.settings => Icons.settings_outlined,
    };
    final selectedIcon = switch (tab) {
      AppTab.potluck => Icons.groups,
      AppTab.whatsCookin => Icons.restaurant_menu,
      AppTab.kaleculations => Icons.analytics,
      AppTab.settings => Icons.settings,
    };

    final label = switch (tab) {
      AppTab.potluck => 'Potluck',
      AppTab.whatsCookin => "What's Cookin?",
      AppTab.kaleculations => 'Kale-culations',
      AppTab.settings => 'Settings',
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
          label,
          style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }

  Widget _buildSidebar(int currentFinderTab) {
    return Container(
      width: _sidebarWidth,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(right: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Material(
        color: Colors.transparent,
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
                setState(() => _currentTab = AppTab.whatsCookin);
              },
              isSelected: _currentTab == AppTab.whatsCookin && currentFinderTab == 1,
            ),
            _buildSidebarItem(
              Icons.restaurant_outlined,
              'My Meals',
              onTap: () {
                ref.read(finderTabProvider.notifier).state = 0;
                setState(() => _currentTab = AppTab.whatsCookin);
              },
              isSelected: _currentTab == AppTab.whatsCookin && currentFinderTab == 0,
            ),
            _buildSidebarItem(
              Icons.eco_outlined,
              'Impact Stats',
              onTap: () => setState(() => _currentTab = AppTab.kaleculations),
              isSelected: _currentTab == AppTab.kaleculations,
            ),
            _buildSidebarItem(
              Icons.people_outline,
              'Following',
              onTap: () => setState(() => _currentTab = AppTab.potluck),
              isSelected: _currentTab == AppTab.potluck,
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
    return InkWell(
      onTap: () {
        debugPrint('Sidebar click: $title');
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? Colors.green[50] : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.green[700] : Colors.grey[700],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.green[700] : Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return switch (_currentTab) {
      AppTab.potluck => const PotluckScreen(),
      AppTab.whatsCookin => const WhatsCookinScreen(),
      AppTab.kaleculations => const KaleculationsScreen(),
      AppTab.settings => const SettingsScreen(),
    };
  }
}

class PotluckScreen extends StatelessWidget {
  const PotluckScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Colors.green,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Discovery'),
              Tab(text: 'Social Feed'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                const DiscoveryScreen(),
                const SocialFeedScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WhatsCookinScreen extends StatelessWidget {
  const WhatsCookinScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Colors.green,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Meal Planner'),
              Tab(text: 'Web Importer'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                const FinderScreen(),
                const RecipeScraperScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class KaleculationsScreen extends StatelessWidget {
  const KaleculationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Colors.green,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Sustainability & Analytics'),
              Tab(text: 'Receipt History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                const AnalyticsScreen(),
                const HistoryScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

