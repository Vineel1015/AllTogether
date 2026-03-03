import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/analytics/screens/analytics_screen.dart';
import '../features/finder/screens/finder_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/social/screens/social_feed_screen.dart';

/// Tab indices used by [AppScaffold].
enum AppTab { social, finder, history, analytics }

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
  AppTab _currentTab = AppTab.social;
  double _sidebarWidth = 250.0;
  bool _isSidebarVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          if (_isSidebarVisible) _buildSidebar(),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: isSelected ? Colors.green[700] : Colors.grey[600],
          backgroundColor: isSelected ? Colors.green[50] : Colors.transparent,
        ),
        onPressed: () => setState(() => _currentTab = tab),
        child: Text(
          tab.name[0].toUpperCase() + tab.name.substring(1),
          style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: _sidebarWidth,
      color: Colors.grey[50],
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
          _buildSidebarItem(Icons.shopping_cart_outlined, 'Shopping List'),
          _buildSidebarItem(Icons.restaurant_outlined, 'My Meals'),
          _buildSidebarItem(Icons.eco_outlined, 'Impact Stats'),
          _buildSidebarItem(Icons.people_outline, 'Following'),
          const Spacer(),
          _buildSidebarItem(Icons.settings_outlined, 'Settings'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      dense: true,
      onTap: () {},
    );
  }

  Widget _buildBody() {
    return switch (_currentTab) {
      AppTab.social => const SocialFeedScreen(),
      AppTab.finder => const FinderScreen(),
      AppTab.history => const HistoryScreen(),
      AppTab.analytics => const AnalyticsScreen(),
    };
  }
}

