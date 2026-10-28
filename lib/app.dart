import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/check_in/presentation/check_in_page.dart';
import 'features/dashboard/presentation/dashboard_page.dart';
import 'features/exposure/presentation/exposure_pages.dart';
import 'features/history/presentation/history_page.dart';
import 'features/insights/presentation/insights_page.dart';
import 'features/settings/presentation/settings_page.dart';
import 'features/urges/presentation/compulsion_urge_page.dart';

final _router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(path: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const DashboardPage()),
        GoRoute(
          path: '/exposures',
          builder: (context, state) => const ExposureListPage(),
        ),
        GoRoute(
          path: '/insights',
          builder: (context, state) => const InsightsPage(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/check-in',
      builder: (context, state) => const CheckInPage(),
    ),
    GoRoute(
      path: '/exposure/new',
      builder: (context, state) => const ExposureFormPage(),
    ),
    GoRoute(
      path: '/session/:id',
      builder: (context, state) =>
          ExposureSessionPage(sessionId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/exposure/start/:id',
      builder: (context, state) =>
          ExposureStartPage(itemId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/urge',
      builder: (context, state) => const CompulsionUrgePage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);

class ExposureCompanionApp extends StatelessWidget {
  const ExposureCompanionApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Exposure Companion',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      );
}

class AppShell extends StatelessWidget {
  const AppShell({required this.path, required this.child, super.key});

  final String path;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final selected = switch (path) {
      '/exposures' => 1,
      '/insights' => 2,
      '/history' => 3,
      _ => 0,
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exposure Companion'),
        actions: [
          IconButton(
            tooltip: 'Settings and privacy',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: child,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Quick actions',
        onPressed: () {
          final router = GoRouter.of(context);
          showModalBottomSheet<void>(
            context: context,
            builder: (sheetContext) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.favorite_outline),
                    title: const Text('Quick check-in'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      router.push('/check-in');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.touch_app_outlined),
                    title: const Text('Record a compulsion urge'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      router.push('/urge');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline),
                    title: const Text('Create an exposure'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      router.push('/exposure/new');
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (index) => context.go(
          const ['/', '/exposures', '/insights', '/history'][index],
        ),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            label: 'Exposure',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
