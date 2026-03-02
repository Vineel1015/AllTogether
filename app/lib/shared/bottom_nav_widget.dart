import 'package:flutter/material.dart';

/// Tab indices used by [AppScaffold] and [BottomNavWidget].
enum AppTab { finder, history, analytics }

/// Bottom navigation bar for the main app.
class BottomNavWidget extends StatelessWidget {
  final AppTab currentTab;
  final ValueChanged<AppTab> onTabSelected;

  const BottomNavWidget({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentTab.index,
      onDestinationSelected: (i) => onTabSelected(AppTab.values[i]),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.restaurant_menu_outlined),
          selectedIcon: Icon(Icons.restaurant_menu),
          label: 'Finder',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'History',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Analytics',
        ),
      ],
    );
  }
}
