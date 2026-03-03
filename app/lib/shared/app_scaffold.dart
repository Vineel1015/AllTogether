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
enum AppTab { potluck, huntAndGather, whatsCookin, kaleculations, settings }

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
      AppTab.huntAndGather => Icons.search_outlined,
      AppTab.whatsCookin => Icons.restaurant_menu_outlined,
      AppTab.kaleculations => Icons.analytics_outlined,
      AppTab.settings => Icons.settings_outlined,
    };
    final selectedIcon = switch (tab) {
      AppTab.potluck => Icons.groups,
      AppTab.huntAndGather => Icons.search,
      AppTab.whatsCookin => Icons.restaurant_menu,
      AppTab.kaleculations => Icons.analytics,
      AppTab.settings => Icons.settings,
    };

    final label = switch (tab) {
      AppTab.potluck => 'Potluck',
      AppTab.huntAndGather => 'Hunt & Gather',
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
              Icons.search_outlined,
              'Hunt & Gather',
              onTap: () => setState(() => _currentTab = AppTab.huntAndGather),
              isSelected: _currentTab == AppTab.huntAndGather,
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
      AppTab.huntAndGather => const RecipeScraperScreen(),
      AppTab.whatsCookin => const FinderScreen(),
      AppTab.kaleculations => const AnalyticsScreen(),
      AppTab.settings => const SettingsScreen(),
    };
  }
}

class PotluckScreen extends ConsumerStatefulWidget {
  const PotluckScreen({super.key});
  @override
  ConsumerState<PotluckScreen> createState() => _PotluckScreenState();
}

class _PotluckScreenState extends ConsumerState<PotluckScreen> {
  bool _isDraggingOverSocial = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              indicatorColor: Colors.green,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: 'Discovery'),
                Tab(text: 'Social Feed'),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                const TabBarView(
                  physics: NeverScrollableScrollPhysics(), // Prevent conflict with drag
                  children: [
                    DiscoveryScreen(),
                    SocialFeedScreen(),
                  ],
                ),
                // Drag Target Overlay for Social Feed
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 100, // Detect drag near the edge
                  child: DragTarget<Meal>(
                    onWillAccept: (data) {
                      setState(() => _isDraggingOverSocial = true);
                      DefaultTabController.of(context).animateTo(1); // Switch to social feed
                      return true;
                    },
                    onLeave: (data) => setState(() => _isDraggingOverSocial = false),
                    onAccept: (meal) {
                      setState(() => _isDraggingOverSocial = false);
                      _showShareDialog(context, meal);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        color: _isDraggingOverSocial 
                            ? Colors.green.withOpacity(0.2) 
                            : Colors.transparent,
                        child: _isDraggingOverSocial 
                            ? const Center(child: Icon(Icons.share, size: 40, color: Colors.green))
                            : const SizedBox.shrink(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context, Meal meal) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Share ${meal.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add a comment to your post:'),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: 'What do you think of this meal?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final user = ref.read(authServiceProvider).currentUser;
              if (user != null) {
                final post = Post(
                  id: '',
                  userId: user.id,
                  username: user.userMetadata?['name'] ?? 'User',
                  userAvatarUrl: '',
                  content: '${commentController.text}\n\nCheck out this meal: ${meal.name}! 🥗',
                  createdAt: DateTime.now(),
                  calories: meal.calories.toDouble(),
                  sustainabilityScore: 9.0,
                  tags: ['potluck', 'discovery'],
                );
                await ref.read(socialFeedProvider.notifier).sharePost(post);
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Post'),
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
    return const FinderScreen();
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
          Container(
            color: Colors.white,
            child: const TabBar(
              indicatorColor: Colors.green,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: 'Sustainability & Analytics'),
                Tab(text: 'Receipt History'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                AnalyticsScreen(),
                HistoryScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

