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

final _session = Session(
  user: const AuthenticatedUser(subject: 'u-1', roles: {ManoRole.requester}),
  accessToken: 'access-1',
  expiresAt: DateTime.now().add(const Duration(minutes: 5)),
);

/// Sign-up succeeds unless a [session] repository says otherwise.
ProviderContainer containerWith([
  RegistrationRepository? repository,
  InMemorySessionRepository? session,
]) => ProviderContainer.test(
  overrides: [
    manoConfigProvider.overrideWithValue(
      const ManoConfig(
        gatewayGraphQlUrl: 'http://gw/graphql',
        appRole: ManoRole.requester,
      ),
    ),
    sessionRepositoryProvider.overrideWithValue(
      session ?? InMemorySessionRepository(onSignUp: () async => Ok(_session)),
    ),
    if (repository != null)
      registrationRepositoryProvider.overrideWithValue(repository),
  ],
);

OnboardingFlowNotifier flowOf(ProviderContainer c) =>
    c.read(onboardingFlowProvider.notifier);

OnboardingRegistration registrationOf(ProviderContainer c) =>
    c.read(onboardingFlowProvider) as OnboardingRegistration;

/// Name, email and password typed; the password step is on screen.
Future<void> toPassword(ProviderContainer c) async {
  await c.read(sessionProvider.future);
  flowOf(c)
    ..startRegistration()
    ..editName(givenName: 'Ana', familyName: 'Rojas')
    ..next()
    ..editEmail('ana@mano.co')
    ..next()
    ..editPassword('mano2026');
}

/// Account created, so the address is next.
Future<void> toAddress(ProviderContainer c, {String givenName = 'Ana'}) async {
  await toPassword(c);
  flowOf(c).editName(givenName: givenName);
  await flowOf(c).createAccount();
}

/// Up to the notifications question, account created.
Future<void> toNotifications(
  ProviderContainer c, {
  String givenName = 'Ana',
}) async {
  await toAddress(c, givenName: givenName);
  flowOf(c)
    ..editAddress('Calle 12 #3-45')
    ..next();
}

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

  test('a finished registration is signed in, with a welcome', () async {
    final container = containerWith();
    await toNotifications(container);

    await flowOf(container).submit();

    expect(container.read(sessionProvider).value, isA<SignedIn>());
    final flow = container.read(onboardingFlowProvider) as OnboardingBrowsing;
    expect(flow.showWelcome, isTrue);
  });

  test('registration opens on the name step with an empty draft', () {
    final container = containerWith();

    flowOf(container).startRegistration();

    final flow = registrationOf(container);
    expect(flow.step, RegistrationStep.name);
    expect(flow.draft, const RegistrationDraft());
    expect(flow.email, '');
    expect(flow.password, '');
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

  group('the account steps', () {
    test('a good name asks for the email next', () {
      final container = containerWith();
      flowOf(container)
        ..startRegistration()
        ..editName(givenName: 'Ana', familyName: 'Rojas')
        ..next();

      expect(registrationOf(container).step, RegistrationStep.email);
    });

    test('a malformed email does not advance, and says why', () {
      final container = containerWith();
      flowOf(container)
        ..startRegistration()
        ..editName(givenName: 'Ana', familyName: 'Rojas')
        ..next()
        ..editEmail('ana@')
        ..next();

      final flow = registrationOf(container);
      expect(flow.step, RegistrationStep.email);
      expect(flow.showProblems, isTrue);
    });

    test('a good email asks for a password', () {
      final container = containerWith();
      flowOf(container)
        ..startRegistration()
        ..editName(givenName: 'Ana', familyName: 'Rojas')
        ..next()
        ..editEmail('ana@mano.co')
        ..next();

      expect(registrationOf(container).step, RegistrationStep.password);
    });

    test('a weak password creates nothing and says why', () async {
      final session = InMemorySessionRepository(
        onSignUp: () async => Ok(_session),
      );
      final container = containerWith(null, session);
      await toPassword(container);
      flowOf(container).editPassword('short');

      await flowOf(container).createAccount();

      expect(registrationOf(container).step, RegistrationStep.password);
      expect(registrationOf(container).showProblems, isTrue);
      expect(session.lastCredentials, isNull);
    });

    test('creating the account signs up and moves on to the address', () async {
      final session = InMemorySessionRepository(
        onSignUp: () async => Ok(_session),
      );
      final container = containerWith(null, session);

      await toAddress(container);

      expect(session.lastCredentials?.email, 'ana@mano.co');
      expect(session.lastCredentials?.password, 'mano2026');
      expect(session.lastSignUpRole, ManoRole.requester);
      expect(container.read(sessionProvider).value, isA<SignedIn>());
      expect(registrationOf(container).step, RegistrationStep.address);
    });

    test('creating the account is observable while in flight', () async {
      final gate = Completer<Result<Session, AuthFailure>>();
      final container = containerWith(
        null,
        InMemorySessionRepository(onSignUp: () => gate.future),
      );
      await toPassword(container);

      final pending = flowOf(container).createAccount();
      expect(registrationOf(container).status, isA<RegistrationSubmitting>());

      gate.complete(Ok(_session));
      await pending;
      expect(registrationOf(container).status, isA<RegistrationIdle>());
    });

    test('a taken email goes back to the email step, saying so', () async {
      final container = containerWith(
        null,
        InMemorySessionRepository(
          onSignUp: () async => const Err(EmailAlreadyRegistered()),
        ),
      );

      await toAddress(container);

      final flow = registrationOf(container);
      expect(flow.step, RegistrationStep.email);
      expect(
        (flow.status as RegistrationAccountRejected).failure,
        isA<EmailAlreadyRegistered>(),
      );
      expect(flow.email, 'ana@mano.co', reason: 'nothing was lost');
      expect(
        (container.read(sessionProvider).value as SignedOut).lastFailure,
        isNull,
        reason: 'the step shows it; the door must not show it again',
      );
    });

    test('an unreachable auth service stays on the password step', () async {
      final container = containerWith(
        null,
        InMemorySessionRepository(
          onSignUp: () async => const Err(AuthUnavailable()),
        ),
      );

      await toAddress(container);

      final flow = registrationOf(container);
      expect(flow.step, RegistrationStep.password);
      expect(
        (flow.status as RegistrationAccountRejected).failure,
        isA<AuthUnavailable>(),
      );
    });

    test('typing again clears the refusal', () async {
      final container = containerWith(
        null,
        InMemorySessionRepository(
          onSignUp: () async => const Err(EmailAlreadyRegistered()),
        ),
      );
      await toAddress(container);

      flowOf(container).editEmail('otra@mano.co');

      expect(registrationOf(container).status, isA<RegistrationIdle>());
    });

    test(
      'once the account exists, the address step does not go back',
      () async {
        final container = containerWith();
        await toAddress(container);

        flowOf(container).back();

        expect(registrationOf(container).step, RegistrationStep.address);
      },
    );

    test('back from the password step returns to the email step', () {
      final container = containerWith();
      flowOf(container)
        ..startRegistration()
        ..editName(givenName: 'Ana', familyName: 'Rojas')
        ..next()
        ..editEmail('ana@mano.co')
        ..next()
        ..back();

      expect(registrationOf(container).step, RegistrationStep.email);
      expect(registrationOf(container).email, 'ana@mano.co');
    });
  });

  test('going back keeps what was typed', () {
    // The whole reason the draft lives out here rather than in a controller
    // inside a screen.
    final container = containerWith();
    flowOf(container)
      ..startRegistration()
      ..editName(givenName: 'Ana', familyName: 'Rojas')
      ..next()
      ..editEmail('ana@mano.co')
      ..back();

    final flow = registrationOf(container);
    expect(flow.step, RegistrationStep.name);
    expect(flow.draft.givenName, 'Ana');
    expect(flow.draft.familyName, 'Rojas');
    expect(flow.email, 'ana@mano.co');
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

  test('the address step will not advance on a scrap of an address', () async {
    final container = containerWith();
    await toAddress(container);
    flowOf(container)
      ..editAddress('C 1')
      ..next();

    expect(registrationOf(container).step, RegistrationStep.address);
    expect(registrationOf(container).showProblems, isTrue);
  });

  test('a good address reaches the notifications question', () async {
    final container = containerWith();
    await toNotifications(container);

    expect(registrationOf(container).step, RegistrationStep.notifications);
  });

  test('submitting is observable while it is in flight', () async {
    final gate = Completer<Result<void, RegistrationFailure>>();
    final container = containerWith(
      _FakeRegistrationRepository(onSubmit: () => gate.future),
    );
    await toNotifications(container);

    final pending = flowOf(container).submit();
    expect(registrationOf(container).status, isA<RegistrationSubmitting>());

    gate.complete(const Ok<void, RegistrationFailure>(null));
    await pending;

    final flow = container.read(onboardingFlowProvider) as OnboardingBrowsing;
    expect(flow.showWelcome, isTrue);
  });

  test('browsing after registering keeps the first name to greet', () async {
    final container = containerWith();
    await toNotifications(container, givenName: 'Ana María');
    await flowOf(container).submit();
    flowOf(container).acknowledgeWelcome();

    final flow = container.read(onboardingFlowProvider) as OnboardingBrowsing;
    expect(flow.name, 'Ana');
  });

  test('the finished draft is what gets submitted', () async {
    final fake = _FakeRegistrationRepository();
    final container = containerWith(fake);
    await toNotifications(container);
    flowOf(container).setWantsPromotions(value: false);

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
    await toNotifications(container);

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
    await toNotifications(container);

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

  group('entering by phone or social sign-in', () {
    Session signedIn({required bool isNew}) => Session(
      user: _session.user,
      accessToken: _session.accessToken,
      expiresAt: _session.expiresAt,
      isNewAccount: isNew,
    );

    test('a new account signs in and is asked its name first', () async {
      final c = containerWith();
      await c.read(sessionProvider.future);
      flowOf(c).startSignIn();

      flowOf(c).enter(signedIn(isNew: true));

      expect(c.read(sessionProvider).value, isA<SignedIn>());
      final flow = registrationOf(c);
      expect(flow.step, RegistrationStep.name);
      expect(flow.hasAccount, isTrue);
    });

    test('the name leads to the address, past email and password', () async {
      final c = containerWith();
      await c.read(sessionProvider.future);
      flowOf(c)
        ..enter(signedIn(isNew: true))
        ..editName(givenName: 'Ana', familyName: 'Rojas')
        ..next();

      expect(registrationOf(c).step, RegistrationStep.address);
    });

    test('there is no stepping back out of an account that exists', () async {
      final c = containerWith();
      await c.read(sessionProvider.future);
      flowOf(c)
        ..enter(signedIn(isNew: true))
        ..back();

      expect(registrationOf(c).step, RegistrationStep.name);
    });

    test('a returning account goes straight in', () async {
      final c = containerWith();
      await c.read(sessionProvider.future);
      flowOf(c).startSignIn();

      flowOf(c).enter(signedIn(isNew: false));

      expect(c.read(sessionProvider).value, isA<SignedIn>());
      expect(c.read(onboardingFlowProvider), isA<OnboardingSignIn>());
    });
  });
}
