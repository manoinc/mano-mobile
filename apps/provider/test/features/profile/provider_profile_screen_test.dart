import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_identity.dart';
import '../../support/fake_provider_profile.dart';
import '../../support/fake_reviews.dart';
import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';
import '../services/services_fakes.dart';

final _liveReviews = FakeReviews(
  rating: const RatingSummary(average: 4.8, count: 12),
  pages: {
    null: ReviewPage(
      items: [
        FakeReviews.review('a', name: 'Laura Pérez'),
        FakeReviews.review('b', name: 'Jorge Ruiz', stars: 4),
      ],
      nextCursor: 'c1',
    ),
    'c1': ReviewPage(items: [FakeReviews.review('c', name: 'Marta Díaz')]),
  },
);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  String path = '/profile',
  SessionRepository? session,
  ReviewRepository? reviews,
  ProviderProfileRepository? profile,
  String? subject = 'w1',
  IdentityVerificationPort? identity,
  List<String>? shared,
  AppearanceStore? appearance,
}) async {
  appearance ??= InMemoryAppearanceStore();
  final overrides = [
    appearanceStoreProvider.overrideWithValue(appearance),
    textSharerProvider.overrideWithValue((text) async => shared?.add(text)),
    if (profile != null)
      providerProfileRepositoryProvider.overrideWithValue(profile),
    serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
    reviewRepositoryProvider.overrideWithValue(reviews ?? _liveReviews),
    if (subject != null)
      currentUserProvider.overrideWithValue(
        AuthenticatedUser(subject: subject, roles: const {}),
      ),
  ];
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final container = await pumpRouterAt(
    tester,
    path,
    overrides: overrides,
    session: session,
    identity: identity ?? FakeIdentityVerification(),
  );
  return container;
}

// Scrolls [text] to the top so the bottom bar can't cover it.
Future<void> _scrollTo(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    400,
    scrollable: find
        .descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
}

// Clear of the bottom bar, which floats over the list's last rows.
Future<void> _centre(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.drag(find.byType(ListView).first, const Offset(0, -300));
  await tester.pumpAndSettle();
}

void main() {
  group('the session row', () {
    testWidgets('signed in, Cerrar sesión signs out', (tester) async {
      final session = FakeSessionRepository(
        onRestore: () async => Ok(fakeSession()),
      );
      final container = await _pump(tester, session: session);
      await container.read(sessionProvider.future);
      await tester.pumpAndSettle();

      await _scrollTo(tester, 'Cerrar sesión');
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(session.signOutCalls, 1);
      expect(container.read(sessionProvider).value, isA<SignedOut>());
    });

    testWidgets('a guest gets Iniciar sesión, back to the door', (
      tester,
    ) async {
      final container = await _pump(tester);
      container.read(sessionProvider.notifier).browseAsGuest();
      await tester.pumpAndSettle();

      expect(find.text('Cerrar sesión'), findsNothing);
      await _scrollTo(tester, 'Iniciar sesión');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(container.read(sessionProvider).value, isA<SignedOut>());
    });
  });

  testWidgets('shows the tasker, the week total and the chart', (tester) async {
    await _pump(tester);
    expect(find.text('Andrés Castro'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsWidgets);
    expect(find.text('\$765.000'), findsOneWidget);
    expect(find.textContaining('Próximo pago'), findsOneWidget);
    expect(find.byType(ManoBarChart), findsOneWidget);
  });

  testWidgets('a nameless pro sees their masked phone, else Tu perfil', (
    tester,
  ) async {
    await _pump(
      tester,
      profile: LiveShapedProfile(displayName: '', phone: '3010000101'),
    );
    expect(find.text('+57 301 *** 0101'), findsOneWidget);
  });

  testWidgets('a pro with no name or phone reads Tu perfil', (tester) async {
    await _pump(
      tester,
      profile: LiveShapedProfile(displayName: '', phone: ''),
    );
    expect(find.text('Tu perfil'), findsOneWidget);
  });

  testWidgets('switching to Este mes changes the total', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Este mes'));
    await tester.pumpAndSettle();
    expect(find.text('\$2.650.000'), findsOneWidget);
  });

  testWidgets('shows the stats grid with the live rating', (tester) async {
    await _pump(tester);
    expect(find.widgetWithText(ManoStatTile, '4,8'), findsOneWidget);
    expect(find.text('118'), findsOneWidget);
    expect(find.text('96 %'), findsOneWidget);
    expect(find.text('98 %'), findsOneWidget);
  });

  testWidgets('without ratings yet the stat reads a dash', (tester) async {
    await _pump(tester, reviews: FakeReviews());
    expect(find.widgetWithText(ManoStatTile, '–'), findsOneWidget);
    expect(find.text('Ver todas'), findsNothing);
  });

  testWidgets('latest live reviews link to all, a page at a time', (
    tester,
  ) async {
    final reviews = FakeReviews(
      rating: _liveReviews.rating,
      pages: _liveReviews.pages,
    );
    await _pump(tester, reviews: reviews);
    expect(find.byType(ManoReviewTile), findsNWidgets(2));
    expect(find.text('Laura Pérez'), findsOneWidget);

    await tester.tap(find.text('Ver todas'));
    await tester.pumpAndSettle();
    final summary = tester.widget<ManoRatingSummary>(
      find.byType(ManoRatingSummary),
    );
    expect(summary.averageLabel, '4,8');
    expect(summary.countLabel, '12 reseñas');
    expect(find.byType(ManoReviewTile), findsNWidgets(2));

    await tester.tap(find.text('Ver más'));
    await tester.pumpAndSettle();

    expect(reviews.reads.last, ('w1', 'c1'));
    expect(find.byType(ManoReviewTile), findsNWidgets(3));
    expect(find.text('Marta Díaz'), findsOneWidget);
    expect(find.text('Ver más'), findsNothing);
  });

  testWidgets('the public preview shows the live rating', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Ver perfil público'));
    await tester.pumpAndSettle();
    expect(find.text('4,8 · 12 reseñas'), findsOneWidget);
  });

  testWidgets('the earnings section opens the breakdown', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Ver desglose'));
    await tester.pumpAndSettle();
    expect(find.text('Trabajos pagados'), findsOneWidget);
    expect(find.textContaining('Laura Pérez'), findsWidgets);
  });

  testWidgets('the services row leads to Mis servicios', (tester) async {
    final c = await _pump(tester);
    await tester.ensureVisible(find.text('Tus servicios y habilidades'));
    await tester.tap(find.text('Tus servicios y habilidades'));
    await tester.pumpAndSettle();
    expect(routerPath(c), '/profile/services');
  });

  testWidgets('Ver perfil público opens the public preview', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Ver perfil público'));
    await tester.pumpAndSettle();
    expect(find.byType(ManoProfileSheet), findsOneWidget);
  });

  testWidgets('the referral card opens a sheet that copies the code', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(tester);
    await _centre(tester, find.byType(ManoReferralCard));
    await tester.tap(find.byType(ManoReferralCard));
    await tester.pumpAndSettle();
    expect(find.text('ANDRES-M4N0'), findsOneWidget);
    expect(find.text('2 colegas invitados · 1 verificado'), findsWidgets);

    await tester.tap(find.text('Copiar código'));
    await tester.pumpAndSettle();
    expect(copied, 'ANDRES-M4N0');
    expect(find.text('Código copiado'), findsOneWidget);
  });

  testWidgets('the card offers coins per verified colleague', (tester) async {
    await _pump(tester);
    await _centre(tester, find.byType(ManoReferralCard));
    expect(
      find.text('Gana 10 Mano coins por cada colega verificado'),
      findsOneWidget,
    );
    expect(find.text('2 colegas invitados · 1 verificado'), findsOneWidget);
  });

  testWidgets('with no invites yet the offer still shows, without counts', (
    tester,
  ) async {
    await _pump(
      tester,
      profile: LiveShapedProfile(
        program: const ReferralProgram(
          code: 'RP-1a2b3c4d',
          coinsPerColleague: 10,
        ),
      ),
    );
    await _centre(tester, find.byType(ManoReferralCard));
    expect(
      find.text('Gana 10 Mano coins por cada colega verificado'),
      findsOneWidget,
    );
    expect(find.textContaining('invitado'), findsNothing);
  });

  testWidgets('Compartir mi código shares the invite link', (tester) async {
    final shared = <String>[];
    await _pump(tester, shared: shared);
    await _centre(tester, find.byType(ManoReferralCard));
    await tester.tap(find.byType(ManoReferralCard));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Compartir mi código'));
    await tester.pumpAndSettle();

    expect(shared.single, contains('ANDRES-M4N0'));
    expect(shared.single, endsWith('https://manoapp.co/r/ANDRES-M4N0'));
  });

  testWidgets('the referral sheet links to Billetera', (tester) async {
    final c = await _pump(tester);
    await _centre(tester, find.byType(ManoReferralCard));
    await tester.tap(find.byType(ManoReferralCard));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver mi Billetera'));
    await tester.pumpAndSettle();
    expect(routerPath(c), '/wallet');
  });

  group('identity', () {
    testWidgets('an unverified pro is asked to verify, opening the photos', (
      tester,
    ) async {
      final session = FakeSessionRepository(
        onRestore: () async => Ok(fakeSession()),
      );
      final c = await _pump(tester, session: session);
      await c.read(sessionProvider.future);
      await tester.pumpAndSettle();

      await _scrollTo(tester, 'Verifica tu identidad');
      await tester.tap(find.text('Verifica tu identidad'));
      await tester.pumpAndSettle();

      expect(routerPath(c), '/profile/identity');
      expect(find.byType(ManoTipList), findsOneWidget);
    });

    testWidgets('an approved check shows Identidad verificada', (tester) async {
      await _pump(
        tester,
        identity: FakeIdentityVerification(const IdentityCheckApproved()),
      );

      await _scrollTo(tester, 'Identidad verificada');
      expect(find.text('Identidad verificada'), findsOneWidget);
    });
  });

  group('live-shaped profile', () {
    testWidgets('shows contact, jobs done and completion, hides the rest', (
      tester,
    ) async {
      await _pump(tester, profile: LiveShapedProfile());

      expect(find.text('Luisa Pérez'), findsOneWidget);
      expect(find.text('luisa@mano.co · 3001112233'), findsOneWidget);
      expect(find.widgetWithText(ManoStatTile, '3'), findsOneWidget);
      expect(find.widgetWithText(ManoStatTile, '75 %'), findsOneWidget);
      expect(find.text('Tasa de respuesta'), findsNothing);
      expect(find.textContaining('años de experiencia'), findsNothing);
    });

    testWidgets('jobs not served yet hide their tiles', (tester) async {
      await _pump(
        tester,
        profile: LiveShapedProfile(stand: const ProviderStats()),
      );

      expect(find.text('Trabajos completados'), findsNothing);
      expect(find.text('Trabajos cumplidos'), findsNothing);
      expect(find.text('Calificación'), findsOneWidget);
    });

    testWidgets('a code-only referral shares the code without a reward', (
      tester,
    ) async {
      await _pump(tester, profile: LiveShapedProfile());
      await _centre(tester, find.byType(ManoReferralCard));
      expect(find.textContaining('Mano coins'), findsNothing);
      // The code sits on its own line so it never splits at the hyphen.
      expect(find.text('Comparte tu código\nRP-1a2b3c4d'), findsOneWidget);

      await tester.tap(find.byType(ManoReferralCard));
      await tester.pumpAndSettle();

      expect(find.text('RP-1a2b3c4d'), findsOneWidget);
      expect(find.textContaining('invitado'), findsNothing);
      expect(find.textContaining('Mano coins'), findsNothing);
      expect(find.textContaining('Comparte tu código con colegas'), findsOne);
      expect(find.text('Copiar código'), findsOneWidget);
      expect(find.text('Compartir mi código'), findsOneWidget);
    });
  });

  testWidgets('Modo oscuro switches the app dark and saves it', (tester) async {
    final store = InMemoryAppearanceStore();
    final c = await _pump(tester, appearance: store);

    await _scrollTo(tester, 'Modo oscuro');
    await tester.tap(find.text('Modo oscuro'));
    await tester.pumpAndSettle();

    expect(c.read(darkModeProvider), isTrue);
    expect(await store.readDark(), isTrue);
  });
}
