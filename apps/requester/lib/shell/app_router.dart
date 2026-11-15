import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/activity/job_detail_screen.dart';
import '../features/checkout/job_checkout_screen.dart';
import '../features/booking/booking_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/explore/search_screen.dart';
import '../features/explore/service_detail_screen.dart';
import '../features/offers/offers_screen.dart';
import '../features/profile/addresses_screen.dart';
import '../features/profile/order_history_screen.dart';
import '../features/profile/payment_methods_screen.dart';
import '../features/profile/personal_info_screen.dart';
import '../features/profile/settings_screen.dart';
import '../features/profile/support_screen.dart';
import '../features/projects/project_detail_screen.dart';
import '../features/projects/publish/publish_project_screen.dart';
import '../features/projects/start_publishing.dart';
import '../features/provider_profile/provider_profile_screen.dart';
import '../features/provider_profile/provider_reviews_screen.dart';
import '../screens/home_tab_screen.dart';
import '../screens/inbox_tab_screen.dart';
import '../screens/profile_tab_screen.dart';
import '../screens/projects_tab_screen.dart';
import 'nav_shell.dart';

/// The nav shell's tabs and each module's routes (docs/modules/index.md).
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
        builder: (context, state, navigationShell) => Consumer(
          builder: (context, ref, _) => NavShell(
            navigationShell: navigationShell,
            onPublish: (category) =>
                startPublishing(context, ref, category: category),
          ),
        ),
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
                  // The pill's way in; the same screen as /profile/addresses.
                  GoRoute(
                    path: 'addresses',
                    builder: (context, state) => const AddressesScreen(),
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
                    path: 'project/:id',
                    builder: (context, state) => ProjectDetailScreen(
                      projectId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'job/:id',
                    builder: (context, state) =>
                        JobDetailScreen(jobId: state.pathParameters['id']!),
                    routes: [_payRoute(rootKey)],
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
                routes: [
                  GoRoute(
                    path: 'personal',
                    builder: (context, state) => const PersonalInfoScreen(),
                  ),
                  GoRoute(
                    path: 'addresses',
                    builder: (context, state) => const AddressesScreen(),
                  ),
                  GoRoute(
                    path: 'payments',
                    builder: (context, state) => const PaymentMethodsScreen(),
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => const OrderHistoryScreen(),
                    routes: [
                      GoRoute(
                        path: 'job/:id',
                        builder: (context, state) =>
                            JobDetailScreen(jobId: state.pathParameters['id']!),
                        routes: [_payRoute(rootKey)],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'support',
                    builder: (context, state) => const SupportScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Reached from offers, quotes and chat, so above the tabs.
      GoRoute(
        path: '/provider/:providerId',
        parentNavigatorKey: rootKey,
        builder: (context, state) => ProviderProfileScreen(
          providerId: state.pathParameters['providerId']!,
        ),
        routes: [
          GoRoute(
            path: 'reviews',
            parentNavigatorKey: rootKey,
            builder: (context, state) => ProviderReviewsScreen(
              providerId: state.pathParameters['providerId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/publish',
        parentNavigatorKey: rootKey,
        builder: (context, state) => PublishProjectScreen(
          initialCategory: state.uri.queryParameters['category'],
        ),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

/// Checkout for a finished job, full screen over the tabs.
GoRoute _payRoute(GlobalKey<NavigatorState> rootKey) => GoRoute(
  path: 'pay',
  parentNavigatorKey: rootKey,
  builder: (context, state) =>
      JobCheckoutScreen(jobId: state.pathParameters['id']!),
);
