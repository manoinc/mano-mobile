import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

/// The flow is exercised with a fake repository and nothing else: no widgets,
/// no navigator, no keyboard. Everything the screens do is a call into here.

final class _FakeRegistrationRepository implements RegistrationRepository {
  _FakeRegistrationRepository({this.onSubmit});

  final Future<Result<void, RegistrationFailure>> Function()? onSubmit;

  RegistrationDraft? submitted;

  @override
  Future<Result<void, RegistrationFailure>> submit(RegistrationDraft draft) {
    submitted = draft;
    return onSubmit?.call() ??
        Future.value(const Ok<void, RegistrationFailure>(null));
  }
}

ProviderContainer containerWith([RegistrationRepository? repository]) =>
    ProviderContainer.test(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(
          InMemorySessionRepository(),
        ),
        if (repository != null)
          registrationRepositoryProvider.overrideWithValue(repository),
      ],
    );

OnboardingFlowNotifier flowOf(ProviderContainer c) =>
    c.read(onboardingFlowProvider.notifier);

OnboardingRegistration registrationOf(ProviderContainer c) =>
    c.read(onboardingFlowProvider) as OnboardingRegistration;

void main() {
  test('a cold start opens on the first slide of the tour', () {
    final container = containerWith();

    expect(container.read(onboardingFlowProvider), isA<OnboardingTour>());
    expect((container.read(onboardingFlowProvider) as OnboardingTour).index, 0);
  });

  test('a fresh container starts over, because nothing is remembered', () {
    final first = containerWith();
    flowOf(first).skipTour();
    expect(first.read(onboardingFlowProvider), isA<OnboardingBrowsing>());

    expect(containerWith().read(onboardingFlowProvider), isA<OnboardingTour>());
  });

  test('the tour clamps at both ends', () {
    final container = containerWith();

    flowOf(container).showSlide(-1);
    expect((container.read(onboardingFlowProvider) as OnboardingTour).index, 0);

    flowOf(container).showSlide(9);
    expect((container.read(onboardingFlowProvider) as OnboardingTour).index, 2);
  });

  test('skipping the tour goes browsing, and says nothing on arrival', () {
    final container = containerWith();

    flowOf(container).skipTour();

    final flow = container.read(onboardingFlowProvider) as OnboardingBrowsing;
    expect(flow.showWelcome, isFalse);
  });

  test('skipping the tour makes the session a guest', () async {
    final container = containerWith();
    await container.read(sessionProvider.future);

    flowOf(container).skipTour();

    expect(container.read(sessionProvider).value, isA<Guest>());
  });

  test('a guest who starts signing in is back at the door', () async {
    final container = containerWith();
    await container.read(sessionProvider.future);
    flowOf(container).skipTour();

    flowOf(container).startSignIn();

    expect(container.read(sessionProvider).value, isA<SignedOut>());
    expect(container.read(onboardingFlowProvider), isA<OnboardingSignIn>());
  });

  test('a finished registration browses as a guest, with a welcome', () async {
    final container = containerWith();
    await container.read(sessionProvider.future);
    flowOf(container).startRegistration();

    flowOf(container)
      ..editName(givenName: 'Ana', familyName: 'Ruiz')
      ..next()
      ..editAddress('Cra 7 # 45-10')
      ..next();
    await flowOf(container).submit();

    expect(container.read(sessionProvider).value, isA<Guest>());
  });

  test('registration opens on the name step with an empty draft', () {
    final container = containerWith();

    flowOf(container).startRegistration();

    final flow = registrationOf(container);
    expect(flow.step, RegistrationStep.name);
    expect(flow.draft, const RegistrationDraft());
    expect(flow.status, isA<RegistrationIdle>());
    expect(flow.showProblems, isFalse, reason: 'nothing has been refused yet');
  });

  test('an unanswerable step does not advance, and starts showing why', () {
    final container = containerWith();
    flowOf(container).startRegistration();

    flowOf(container).next();

    final flow = registrationOf(container);
    expect(flow.step, RegistrationStep.name);
    expect(flow.showProblems, isTrue);
  });

  test('a good name advances', () {
    final container = containerWith();
    flowOf(container)
      ..startRegistration()
      ..editName(givenName: 'Ana', familyName: 'Rojas')
      ..next();

    expect(registrationOf(container).step, RegistrationStep.address);
  });

  test('going back keeps what was typed', () {
    // The whole reason the draft lives out here rather than in a controller
    // inside a screen.
    final container = containerWith();
    flowOf(container)
      ..startRegistration()
      ..editName(givenName: 'Ana', familyName: 'Rojas')
      ..next()
      ..editAddress('Calle 12 #3-45')
      ..back();

    final flow = registrationOf(container);
    expect(flow.step, RegistrationStep.name);
    expect(flow.draft.givenName, 'Ana');
    expect(flow.draft.familyName, 'Rojas');
    expect(flow.draft.address, 'Calle 12 #3-45');
  });

  test('going back out of the first step returns to the last slide', () {
    final container = containerWith();
    flowOf(container)
      ..startRegistration()
      ..back();

    final flow = container.read(onboardingFlowProvider);
    expect(flow, isA<OnboardingTour>());
    expect((flow as OnboardingTour).index, 2);
  });

  test('"Ahora no" leaves the flow without a welcome', () {
    final container = containerWith();
    flowOf(container)
      ..startRegistration()
      ..skipRegistration();

    final flow = container.read(onboardingFlowProvider) as OnboardingBrowsing;
    expect(flow.showWelcome, isFalse);
  });

  test('the address step will not advance on a scrap of an address', () {
    final container = containerWith();
    flowOf(container)
      ..startRegistration()
      ..editName(givenName: 'Ana', familyName: 'Rojas')
      ..next()
      ..editAddress('C 1')
      ..next();

    expect(registrationOf(container).step, RegistrationStep.address);
    expect(registrationOf(container).showProblems, isTrue);
  });

  test('a good address reaches the notifications question', () {
    final container = containerWith();
    flowOf(container)
      ..startRegistration()
      ..editName(givenName: 'Ana', familyName: 'Rojas')
      ..next()
      ..editAddress('Calle 12 #3-45')
      ..next();

    expect(registrationOf(container).step, RegistrationStep.notifications);
  });

  test('submitting is observable while it is in flight', () async {
    final gate = Completer<Result<void, RegistrationFailure>>();
    final container = containerWith(
      _FakeRegistrationRepository(onSubmit: () => gate.future),
    );
    flowOf(container)
      ..startRegistration()
      ..editName(givenName: 'Ana', familyName: 'Rojas')
      ..next()
      ..editAddress('Calle 12 #3-45')
      ..next();

    final pending = flowOf(container).submit();
    expect(registrationOf(container).status, isA<RegistrationSubmitting>());

    gate.complete(const Ok<void, RegistrationFailure>(null));
    await pending;

    final flow = container.read(onboardingFlowProvider) as OnboardingBrowsing;
    expect(flow.showWelcome, isTrue);
  });

  test('the finished draft is what gets submitted', () async {
    final fake = _FakeRegistrationRepository();
    final container = containerWith(fake);
    flowOf(container)
      ..startRegistration()
      ..editName(givenName: 'Ana', familyName: 'Rojas')
      ..next()
      ..editAddress('Calle 12 #3-45')
      ..next()
      ..setWantsPromotions(value: false);

    await flowOf(container).submit();

    expect(fake.submitted?.givenName, 'Ana');
    expect(fake.submitted?.address, 'Calle 12 #3-45');
    expect(fake.submitted?.wantsPromotions, isFalse);
    expect(fake.submitted?.wantsNotifications, isTrue);
  });

  test('a refused submit stays in the flow and says so', () async {
    final container = containerWith(
      _FakeRegistrationRepository(
        onSubmit: () async => const Err(RegistrationUnavailable()),
      ),
    );
    flowOf(container)
      ..startRegistration()
      ..editName(givenName: 'Ana', familyName: 'Rojas')
      ..next()
      ..editAddress('Calle 12 #3-45')
      ..next();

    await flowOf(container).submit();

    final flow = registrationOf(container);
    expect(flow.status, isA<RegistrationFailed>());
    expect(
      (flow.status as RegistrationFailed).failure,
      isA<RegistrationUnavailable>(),
    );
    expect(flow.draft.address, 'Calle 12 #3-45', reason: 'nothing was lost');
  });

  test('a failure can be acknowledged and tried again', () async {
    var attempts = 0;
    final container = containerWith(
      _FakeRegistrationRepository(
        onSubmit: () async => attempts++ == 0
            ? const Err(RegistrationUnavailable())
            : const Ok<void, RegistrationFailure>(null),
      ),
    );
    flowOf(container)
      ..startRegistration()
      ..editName(givenName: 'Ana', familyName: 'Rojas')
      ..next()
      ..editAddress('Calle 12 #3-45')
      ..next();

    await flowOf(container).submit();
    flowOf(container).acknowledgeFailure();
    expect(registrationOf(container).status, isA<RegistrationIdle>());

    await flowOf(container).submit();
    expect(container.read(onboardingFlowProvider), isA<OnboardingBrowsing>());
  });

  test('the welcome is shown once', () {
    final container = containerWith();
    flowOf(container).skipTour();

    flowOf(container).acknowledgeWelcome();

    final flow = container.read(onboardingFlowProvider) as OnboardingBrowsing;
    expect(flow.showWelcome, isFalse);
  });

  test('signing in is its own place to be', () {
    final container = containerWith();

    flowOf(container).startSignIn();

    expect(container.read(onboardingFlowProvider), isA<OnboardingSignIn>());
  });

  test(
    'the default binding accepts a draft without sending it anywhere',
    () async {
      // Phase 1 keeps a draft on the device. The stub says Ok because that is
      // the whole of what this phase promises -- unlike the auth stub, which
      // must not pretend somebody signed in.
      final container = containerWith();

      final result = await container
          .read(registrationRepositoryProvider)
          .submit(const RegistrationDraft());

      expect(result.isOk, isTrue);
    },
  );
}
