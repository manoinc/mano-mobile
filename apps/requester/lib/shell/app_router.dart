import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_tab_screen.dart';
import '../screens/inbox_tab_screen.dart';
import '../screens/profile_tab_screen.dart';
import '../screens/projects_tab_screen.dart';
import 'nav_shell.dart';

/// The nav shell's four tabs. Who gets to see this router at all -- carousel,
/// sign-in, registration, or browsing -- is [ManoRoot]'s decision, made
/// before this is ever mounted; there is nothing left here to gate.
///
/// Built once, not per rebuild -- a fresh [GoRouter] would reset each tab's
/// navigation state.
final requesterRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            NavShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects',
                builder: (context, state) => const ProjectsTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inbox',
                builder: (context, state) => const InboxTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileTabScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
