import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/activity/job_detail_screen.dart';
import '../features/booking/booking_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/explore/search_screen.dart';
import '../features/explore/service_detail_screen.dart';
import '../features/offers/offers_screen.dart';
import '../screens/home_tab_screen.dart';
import '../screens/inbox_tab_screen.dart';
import '../screens/profile_tab_screen.dart';
import '../screens/projects_tab_screen.dart';
import 'nav_shell.dart';

/// The nav shell's tabs and each module's routes (docs/modules/README.md).
///
/// Who sees this router at all is [ManoRoot]'s decision. Built once, not per
/// rebuild: a fresh [GoRouter] would reset each tab's navigation state.
final requesterRouterProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootKey,
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
                routes: [
                  GoRoute(
                    path: 'search',
                    builder: (context, state) => SearchScreen(
                      category: state.uri.queryParameters['category'],
                    ),
                  ),
                  GoRoute(
                    path: 'service/:id',
                    builder: (context, state) => ServiceDetailScreen(
                      serviceId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'offers',
                        builder: (context, state) => OffersScreen(
                          serviceId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'book/:offerId',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => BookingScreen(
                      offerId: state.pathParameters['offerId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects',
                builder: (context, state) => const ProjectsTabScreen(),
                routes: [
                  GoRoute(
                    path: 'job/:id',
                    builder: (context, state) =>
                        JobDetailScreen(jobId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inbox',
                builder: (context, state) => const InboxTabScreen(),
                routes: [
                  GoRoute(
                    path: ':conversationId',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => ChatScreen(
                      conversationId: state.pathParameters['conversationId']!,
                    ),
                  ),
                ],
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
