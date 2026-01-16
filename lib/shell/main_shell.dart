import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/glass_bottom_nav_bar.dart';

/// Main shell with liquid glass bottom navigation (5 tabs)
class MainShell extends StatefulWidget {
  final Widget child;
  
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/analytics')) return 1;
    if (location.startsWith('/budgets')) return 2;
    if (location.startsWith('/menu')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/analytics');
        break;
      case 2:
        context.go('/budgets');
        break;
      case 3:
        context.go('/menu');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    
    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: GlassBottomNavBar(
        currentIndex: selectedIndex,
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          GlassNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          GlassNavItem(
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart,
            label: 'Analytics',
          ),
          GlassNavItem(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet,
            label: 'Budgets',
          ),
          GlassNavItem(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view,
            label: 'More',
          ),
          GlassNavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
