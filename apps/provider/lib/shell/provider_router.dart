import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/agenda/agenda_job_screen.dart';
import '../features/agenda/agenda_screen.dart';
import '../features/availability/availability_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/provider_inbox_screen.dart';
import '../features/requests/requests_screen.dart';
import '../features/services/my_services_screen.dart';
import '../features/services/offer_editor_screen.dart';
import 'provider_nav_shell.dart';

/// The provider's tabs and each module's routes (docs/modules/README.md).
/// Built once, not per rebuild, so each tab keeps its navigation state.
final providerRouterProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/requests',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ProviderNavShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/requests',
                builder: (context, state) => const RequestsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/agenda',
                builder: (context, state) => const AgendaScreen(),
                routes: [
                  GoRoute(
                    path: 'job/:id',
                    builder: (context, state) =>
                        AgendaJobScreen(jobId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inbox',
                builder: (context, state) => const ProviderInboxScreen(),
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
                path: '/services',
                builder: (context, state) => const MyServicesScreen(),
                routes: [
                  GoRoute(
                    path: 'availability',
                    builder: (context, state) => const AvailabilityScreen(),
                  ),
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => const OfferEditorScreen(),
                  ),
                  GoRoute(
                    path: 'offer/:id',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) =>
                        OfferEditorScreen(offerId: state.pathParameters['id']!),
                  ),
                ],
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
