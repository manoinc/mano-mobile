import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/pump_app.dart';
import '../projects/projects_fakes.dart';
import 'provider_profile_fakes.dart';

const _route = '/provider/w1';

List<Override> _fakes({FakeDirectory? directory, FakeReviews? reviews}) => [
  providerDirectoryProvider.overrideWithValue(directory ?? FakeDirectory()),
  reviewRepositoryProvider.overrideWithValue(reviews ?? FakeReviews()),
];

void _phone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollToReviews(WidgetTester tester) =>
    _scrollTo(tester, find.text('Reseñas'));

void main() {
  testWidgets('the header shows name, verified badge and rating', (
    tester,
  ) async {
    _phone(tester);
    await pumpRouterAt(tester, _route, overrides: _fakes());

    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
    final summary = tester.widget<ManoRatingSummary>(
      find.byType(ManoRatingSummary),
    );
    expect(summary.averageLabel, '4,9');
    expect(summary.countLabel, '32 reseñas');
  });

  testWidgets('shows the bio, skills and portfolio', (tester) async {
    _phone(tester);
    await pumpRouterAt(tester, _route, overrides: _fakes());

    expect(find.text('Sobre mí'), findsOneWidget);
    expect(find.text('Plomera certificada.'), findsOneWidget);
    expect(find.text('Plomería'), findsOneWidget);
    expect(find.text('Remodelación'), findsOneWidget);
    expect(
      tester.widget<ManoPhotoGallery>(find.byType(ManoPhotoGallery)).urls,
      fakeProvider.portfolioUrls,
    );
  });

  testWidgets('no portfolio says so instead of an empty strip', (tester) async {
    _phone(tester);
    final directory = FakeDirectory(
      Ok(
        PublicProviderProfile(
          party: fakeProvider.party,
          bio: '',
          verified: false,
        ),
      ),
    );
    await pumpRouterAt(tester, _route, overrides: _fakes(directory: directory));

    expect(find.byType(ManoPhotoGallery), findsNothing);
    expect(find.text('Aún no hay fotos de trabajos'), findsOneWidget);
    expect(find.text('Sobre mí'), findsNothing);
    expect(find.byIcon(Icons.verified), findsNothing);
  });

  testWidgets('an unnamed provider is called Profesional', (tester) async {
    _phone(tester);
    final directory = FakeDirectory(
      const Ok(
        PublicProviderProfile(
          party: Party(id: 'w1', displayName: ' ', photoUrl: ''),
          bio: '',
          verified: false,
        ),
      ),
    );
    await pumpRouterAt(tester, _route, overrides: _fakes(directory: directory));

    expect(find.text('Profesional'), findsOneWidget);
  });

  testWidgets('shows the three newest reviews and a way to all of them', (
    tester,
  ) async {
    _phone(tester);
    await pumpRouterAt(tester, _route, overrides: _fakes());
    await _scrollTo(tester, find.text('Ver las 32 reseñas'));

    expect(find.byType(ManoReviewTile), findsNWidgets(3));
    expect(find.text('Llegó a la hora.'), findsOneWidget);
    expect(find.text('Volvería a contratarla.'), findsNothing);
    expect(find.text('Ver las 32 reseñas'), findsOneWidget);
  });

  testWidgets('a provider without reviews is new, with nothing to list', (
    tester,
  ) async {
    _phone(tester);
    final reviews = FakeReviews(
      rating: RatingSummary.none,
      pages: {null: const ReviewPage(items: [])},
    );
    await pumpRouterAt(tester, _route, overrides: _fakes(reviews: reviews));

    expect(find.text('Aún sin reseñas'), findsOneWidget);
    expect(find.byType(ManoReviewTile), findsNothing);
    expect(find.textContaining('Ver las'), findsNothing);
  });

  testWidgets('Ver las reseñas opens every review, a page at a time', (
    tester,
  ) async {
    _phone(tester);
    final container = await pumpRouterAt(tester, _route, overrides: _fakes());

    await _scrollTo(tester, find.text('Ver las 32 reseñas'));
    await _tap(tester, find.text('Ver las 32 reseñas'));

    expect(routerPath(container), '/provider/w1/reviews');
    expect(find.text('32 reseñas'), findsWidgets);
    expect(find.text('Volvería a contratarla.'), findsOneWidget);
    expect(find.text('La recomiendo.'), findsNothing);

    await _scrollTo(tester, find.text('Ver más'));
    await _tap(tester, find.text('Ver más'));
    await _scrollTo(tester, find.text('La recomiendo.'));

    expect(find.text('La recomiendo.'), findsOneWidget);
    expect(find.text('Ver más'), findsNothing);
  });

  testWidgets('shows a skeleton while loading', (tester) async {
    _phone(tester);
    final directory = FakeDirectory()..gate = Completer<void>();
    await pumpRouterAt(tester, _route, overrides: _fakes(directory: directory));
    await tester.pump();

    expect(find.byKey(const Key('provider-profile-skeleton')), findsOneWidget);
    directory.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('provider-profile-skeleton')), findsNothing);
    expect(find.text('Ana Gómez'), findsOneWidget);
  });

  testWidgets('an unknown provider says so', (tester) async {
    _phone(tester);
    await pumpRouterAt(
      tester,
      _route,
      overrides: _fakes(directory: FakeDirectory(const Err(DataNotFound()))),
    );

    expect(find.text('No encontramos a este profesional'), findsOneWidget);
    expect(find.text('Escribir'), findsNothing);
  });

  testWidgets('a failed load offers a retry', (tester) async {
    _phone(tester);
    final directory = FakeDirectory(const Err(DataUnavailable()));
    await pumpRouterAt(tester, _route, overrides: _fakes(directory: directory));

    expect(find.text('No pudimos cargar el perfil'), findsOneWidget);
    directory.answer = const Ok(fakeProvider);
    await _tap(tester, find.text('Reintentar'));

    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(directory.calls, 2);
  });

  testWidgets('Escribir asks a guest to sign in first', (tester) async {
    _phone(tester);
    await pumpRouterAt(tester, _route, overrides: _fakes());

    await _tap(tester, find.text('Escribir'));

    expect(find.byType(ManoAccountNeededSheet), findsOneWidget);
  });

  testWidgets('Escribir opens a chat with the provider', (tester) async {
    _phone(tester);
    final container = await pumpRouterAt(
      tester,
      _route,
      overrides: _fakes(),
      session: signedIn(),
    );

    await _tap(tester, find.text('Escribir'));

    expect(routerPath(container), '/inbox/conv-with-w1');
  });

  testWidgets('with default mocks, provider-1 shows a real profile', (
    tester,
  ) async {
    _phone(tester);
    await pumpRouterAt(tester, '/provider/provider-1');

    expect(find.text('Andrés Castro'), findsOneWidget);
    await _scrollToReviews(tester);
    expect(find.byType(ManoReviewTile), findsWidgets);
  });
}
