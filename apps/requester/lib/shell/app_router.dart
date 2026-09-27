import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';

import '../screens/home_tab_screen.dart';
import '../screens/inbox_tab_screen.dart';
import '../screens/profile_tab_screen.dart';
import '../screens/projects_tab_screen.dart';
import '../screens/sign_in_screen.dart';
import 'nav_shell.dart';
import 'session_refresh_listenable.dart';

/// Built once, not per rebuild -- a fresh [GoRouter] would leak the
/// [SessionRefreshListenable]'s subscription and reset navigation state.
final requesterRouterProvider = Provider<GoRouter>((ref) {
  final refresh = SessionRefreshListenable(ref);

  final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final loggingIn = state.matchedLocation == '/sign-in';

      // Still restoring a stored session -- nothing to redirect to yet.
      if (session.value == null && !session.hasError) return null;

      final signedIn = session.value is SignedIn;
      if (!signedIn && !loggingIn) return '/sign-in';
      if (signedIn && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        // Watched, not read: a failed sign-in keeps the location at /sign-in,
        // and go_router does not rebuild a page whose location is unchanged.
        // Only watching here lets the failure notice appear and clear.
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final value = ref.watch(sessionProvider).value;
            final failure = value is SignedOut ? value.lastFailure : null;
            return SignInScreen(failure: failure);
          },
        ),
      ),
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

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
