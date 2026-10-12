import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/agenda/agenda_job_screen.dart';
import '../features/agenda/agenda_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/provider_inbox_screen.dart';
import '../features/home/provider_home_screen.dart';
import '../features/services/my_services_screen.dart';
import '../features/services/offer_editor_screen.dart';
import 'module_placeholder.dart';
import 'provider_nav_shell.dart';

/// The provider's tabs and each module's routes (docs/modules/index.md).
/// Built once, not per rebuild, so each tab keeps its navigation state.
final providerRouterProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/home',
    redirect: (context, state) => _legacy(state.uri.path),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ProviderNavShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const ProviderHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/agenda',
                builder: (context, state) => AgendaScreen(
                  initialTab: state.uri.queryParameters['tab'] == 'availability'
                      ? AgendaTab.availability
                      : AgendaTab.calendar,
                ),
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
                path: '/wallet',
                builder: (context, state) => const ModulePlaceholder(
                  title: 'Billetera',
                  detail: 'Tus Mano coins para responder solicitudes.',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ModulePlaceholder(
                  title: 'Perfil',
                  detail: 'Ganancias, reseñas y tus servicios.',
                ),
                routes: [
                  GoRoute(
                    path: 'services',
                    builder: (context, state) => const MyServicesScreen(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        parentNavigatorKey: rootKey,
                        builder: (context, state) => const OfferEditorScreen(),
                      ),
                      GoRoute(
                        path: 'offer/:id',
                        parentNavigatorKey: rootKey,
                        builder: (context, state) => OfferEditorScreen(
                          offerId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
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

// Links from before the tabs moved still land.
String? _legacy(String path) => switch (path) {
  '/requests' => '/home',
  '/agenda/availability' ||
  '/services/availability' => '/agenda?tab=availability',
  _ when path.startsWith('/services') => '/profile$path',
  _ => null,
};
