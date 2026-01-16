import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Menu page with all services that don't fit in bottom nav
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
        children: [
          // Financial Tools Section
          _buildSectionHeader('Financial Tools'),
          _buildMenuGrid([
            _MenuItem(
              icon: Icons.savings,
              label: 'Savings Goals',
              color: Colors.green,
              route: '/savings-goals',
            ),
            _MenuItem(
              icon: Icons.repeat,
              label: 'Recurring',
              color: Colors.blue,
              route: '/recurring-expenses',
            ),
            _MenuItem(
              icon: Icons.account_balance_wallet,
              label: 'Income',
              color: Colors.teal,
              route: '/income',
            ),
            _MenuItem(
              icon: Icons.speed,
              label: 'Limits',
              color: Colors.orange,
              route: '/spending-limits',
            ),
            _MenuItem(
              icon: Icons.dashboard_customize,
              label: 'Templates',
              color: Colors.purple,
              route: '/budget-templates',
            ),
            _MenuItem(
              icon: Icons.file_download,
              label: 'Export',
              color: Colors.indigo,
              route: '/export',
            ),
            _MenuItem(
              icon: Icons.category,
              label: 'Categories',
              color: Colors.pink,
              route: '/categories',
            ),
          ], context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMenuGrid(List<_MenuItem> items, BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: items.map((item) => _buildMenuItem(item, context)).toList(),
    );
  }

  Widget _buildMenuItem(_MenuItem item, BuildContext context) {
    return InkWell(
      onTap: () => context.push(item.route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: item.color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: item.color.withAlpha(40)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: item.color, size: 26),
            const SizedBox(height: 6),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: item.color.withAlpha(220),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}
