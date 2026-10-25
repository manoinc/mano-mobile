import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_requester/features/activity/job_detail_screen.dart';
import 'package:mano_requester/features/booking/booking_screen.dart';
import 'package:mano_requester/features/chat/chat_screen.dart';
import 'package:mano_requester/features/explore/search_screen.dart';
import 'package:mano_requester/features/explore/service_detail_screen.dart';
import 'package:mano_requester/features/offers/offers_screen.dart';
import 'package:mano_requester/screens/home_tab_screen.dart';
import 'package:mano_requester/shell/app_router.dart';
import 'package:mano_requester/shell/nav_shell.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../support/fake_session_repository.dart';

/// The real [requesterRouterProvider] on its own, without [ManoRoot]'s
/// doorway around it -- who gets to see this router is [ManoRoot]'s
/// decision, made before it is ever mounted; these tests are only about the
/// shape of the router itself.
Future<ProviderContainer> _pump(WidgetTester tester) async {
  final container = ProviderContainer.test(
    overrides: [
      sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
      offlineMarketplaceProvider.overrideWithValue(true),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          theme: ManoTheme.light(),
          routerConfig: ref.watch(requesterRouterProvider),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

String _location(ProviderContainer container) => container
    .read(requesterRouterProvider)
    .routerDelegate
    .currentConfiguration
    .uri
    .toString();

void main() {
  testWidgets('opens onto /home inside the shell', (tester) async {
    final container = await _pump(tester);

    expect(_location(container), '/home');
    expect(find.byType(NavShell), findsOneWidget);
    expect(find.byType(HomeTabScreen), findsOneWidget);
  });

  test('the router is built once per container', () {
    final container = ProviderContainer.test(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
      ],
    );

    final GoRouter first = container.read(requesterRouterProvider);
    expect(container.read(requesterRouterProvider), same(first));
  });

  group('module routes', () {
    Future<void> go(WidgetTester tester, ProviderContainer c, String to) async {
      c.read(requesterRouterProvider).go(to);
      await tester.pumpAndSettle();
    }

    testWidgets('explore: search with an optional category', (tester) async {
      final c = await _pump(tester);
      await go(tester, c, '/home/search?category=cleaning');
      expect(
        tester.widget<SearchScreen>(find.byType(SearchScreen)).category,
        'cleaning',
      );
    });

    testWidgets('explore: service detail by id', (tester) async {
      final c = await _pump(tester);
      await go(tester, c, '/home/service/s1');
      expect(
        tester
            .widget<ServiceDetailScreen>(find.byType(ServiceDetailScreen))
            .serviceId,
        's1',
      );
    });

    testWidgets('offers for a service', (tester) async {
      final c = await _pump(tester);
      await go(tester, c, '/home/service/s1/offers');
      expect(
        tester.widget<OffersScreen>(find.byType(OffersScreen)).serviceId,
        's1',
      );
    });

    testWidgets('booking is full screen, above the nav bar', (tester) async {
      final c = await _pump(tester);
      await go(tester, c, '/home/book/o1');
      expect(
        tester.widget<BookingScreen>(find.byType(BookingScreen)).offerId,
        'o1',
      );
      expect(find.byType(ManoBottomNavBar), findsNothing);
    });

    testWidgets('activity: job detail', (tester) async {
      final c = await _pump(tester);
      await go(tester, c, '/projects/job/j1');
      expect(
        tester.widget<JobDetailScreen>(find.byType(JobDetailScreen)).jobId,
        'j1',
      );
    });

    testWidgets('chat is full screen, above the nav bar', (tester) async {
      final c = await _pump(tester);
      await go(tester, c, '/inbox/conv-1');
      expect(
        tester.widget<ChatScreen>(find.byType(ChatScreen)).conversationId,
        'conv-1',
      );
      expect(find.byType(ManoBottomNavBar), findsNothing);
    });
  });

  testWidgets('the search pill opens search', (tester) async {
    final c = await _pump(tester);
    await tester.tap(find.byType(ManoSearchPill));
    await tester.pumpAndSettle();
    expect(c.read(requesterRouterProvider).state.uri.path, '/home/search');
  });

  testWidgets('a conversation opens its chat', (tester) async {
    final c = await _pump(tester);
    await tester.tap(find.text('Bandeja'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ManoConversationTile).first);
    await tester.pumpAndSettle();
    expect(c.read(requesterRouterProvider).state.uri.path, '/inbox/conv-1');
  });
}
