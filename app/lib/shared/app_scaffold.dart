import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/finder/screens/finder_screen.dart';
import '../features/history/screens/history_screen.dart';
import 'bottom_nav_widget.dart';

/// Main app shell shown to authenticated users who have completed onboarding.
///
/// Holds bottom navigation state and swaps the body between tabs.
/// Feature screens for Finder, History, and Analytics are added here
/// as each session is implemented.
class AppScaffold extends ConsumerStatefulWidget {
  const AppScaffold({super.key});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  AppTab _currentTab = AppTab.finder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavWidget(
        currentTab: _currentTab,
        onTabSelected: (tab) => setState(() => _currentTab = tab),
      ),
    );
  }

  Widget _buildBody() {
    return switch (_currentTab) {
      AppTab.finder => const FinderScreen(),
      AppTab.history => const HistoryScreen(),
      AppTab.analytics => const _AnalyticsPlaceholder(),
    };
  }
}

// ── Placeholder screens (replaced in later sessions) ──────────────────────────

class _AnalyticsPlaceholder extends StatelessWidget {
  const _AnalyticsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: const Center(child: Text('Analytics — coming in Session 4')),
    );
  }
}
