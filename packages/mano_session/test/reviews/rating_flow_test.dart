import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

import 'fake_reviews.dart';

void main() {
  late FakeReviews reviews;

  ProviderContainer make(String role) => ProviderContainer.test(
    overrides: [
      manoConfigProvider.overrideWithValue(
        ManoConfig(gatewayGraphQlUrl: 'http://gw/graphql', appRole: role),
      ),
      reviewRepositoryProvider.overrideWithValue(reviews),
    ],
  );

  setUp(() => reviews = FakeReviews());

  test('starts empty and cannot be sent until a star is chosen', () {
    final container = make(ManoRole.requester);
    final flow = container.read(ratingFlowProvider('j1'));

    expect(flow.draft, const ReviewDraft());
    expect(flow.canSubmit, isFalse);
    expect(flow.isDone, isFalse);

    container.read(ratingFlowProvider('j1').notifier).setStars(4);
    expect(container.read(ratingFlowProvider('j1')).canSubmit, isTrue);
  });

  test(
    'the requester app rates the provider and remembers the stars',
    () async {
      final container = make(ManoRole.requester);
      final flow = container.read(ratingFlowProvider('j1').notifier)
        ..setStars(4)
        ..setComment('  Puntual  ');

      expect(await flow.submit(), isTrue);

      expect(reviews.writes, [('provider', 'j1', 4, 'Puntual')]);
      final state = container.read(ratingFlowProvider('j1'));
      expect(state.isDone, isTrue);
      expect(state.ratedStars, 4);
      expect(container.read(ratedStarsProvider('j1')), 4);
    },
  );

  test('the provider app rates the client', () async {
    final container = make(ManoRole.provider);
    final flow = container.read(ratingFlowProvider('j2').notifier)..setStars(5);

    await flow.submit();

    expect(reviews.writes.single.$1, 'client');
  });

  test('a repeat shows the stored stars, not the draft', () async {
    reviews.written = Ok(FakeReviews.review('r', stars: 2));
    final container = make(ManoRole.requester);
    final flow = container.read(ratingFlowProvider('j1').notifier)..setStars(5);

    await flow.submit();

    expect(container.read(ratedStarsProvider('j1')), 2);
  });

  test('a job the service has not seen finish says to try later', () async {
    reviews.written = const Err(DataRejected(reason: 'FailedPrecondition: x'));
    final container = make(ManoRole.requester);
    final flow = container.read(ratingFlowProvider('j1').notifier)..setStars(3);

    expect(await flow.submit(), isFalse);

    final state = container.read(ratingFlowProvider('j1'));
    expect(
      state.error,
      'Aún no puedes calificar este trabajo. Intenta en unos minutos.',
    );
    expect(state.busy, isFalse);
    expect(state.isDone, isFalse);
    expect(container.read(ratedStarsProvider('j1')), isNull);
  });

  test('any other failure says to try again', () async {
    reviews.written = const Err(DataUnavailable());
    final container = make(ManoRole.requester);
    final flow = container.read(ratingFlowProvider('j1').notifier)..setStars(3);

    await flow.submit();

    expect(
      container.read(ratingFlowProvider('j1')).error,
      'No pudimos enviar tu calificación. Intenta de nuevo.',
    );
  });

  test('a comment over the limit is refused before it is sent', () async {
    final container = make(ManoRole.requester);
    final flow = container.read(ratingFlowProvider('j1').notifier)
      ..setStars(3)
      ..setComment('a' * 4001);

    expect(await flow.submit(), isFalse);

    expect(reviews.writes, isEmpty);
    expect(
      container.read(ratingFlowProvider('j1')).error,
      'Tu comentario es muy largo. Máximo 4000 caracteres.',
    );
  });

  test('changing the draft clears the last error', () async {
    reviews.written = const Err(DataUnavailable());
    final container = make(ManoRole.requester);
    final flow = container.read(ratingFlowProvider('j1').notifier)..setStars(3);
    await flow.submit();

    flow.setStars(4);

    expect(container.read(ratingFlowProvider('j1')).error, isNull);
  });
}
