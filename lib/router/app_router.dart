import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/login_page.dart';
import '../auth/register_page.dart';
import '../dashboard/dashboard_page.dart';
import '../analytics/analytics_page.dart';
import '../budgets/budgets_page.dart';
import '../budgets/add_budget_page.dart';
import '../settings/settings_page.dart';
import '../categories/categories_page.dart';
import '../export/export_page.dart';
import '../expenses/add_expense_page.dart';
import '../shell/main_shell.dart';
import '../services/supabase_service.dart';

/// Navigation key for nested navigation
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

/// App router configuration using GoRouter
class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = SupabaseService.instance.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // If not logged in and not on auth page, redirect to login
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // If logged in and on auth page, redirect to dashboard
      if (isLoggedIn && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),

      // Main app with bottom navigation shell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardPage(),
            ),
          ),
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalyticsPage(),
            ),
          ),
          GoRoute(
            path: '/budgets',
            name: 'budgets',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BudgetsPage(),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
          ),
        ],
      ),

      // Full-screen routes (no bottom nav)
      GoRoute(
        path: '/add-expense',
        name: 'add-expense',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddExpensePage(),
      ),
      GoRoute(
        path: '/add-budget',
        name: 'add-budget',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddBudgetPage(),
      ),
      GoRoute(
        path: '/categories',
        name: 'categories',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CategoriesPage(),
      ),
      GoRoute(
        path: '/export',
        name: 'export',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExportPage(),
      ),
    ],
  );
}
