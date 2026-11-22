import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

final class _RecordingOnboarding implements ProviderOnboardingRepository {
  _RecordingOnboarding(this.result);

  final Result<VerificationStatus, DataFailure> result;
  final submitted = <WorkerProfileDraft>[];

  @override
  Future<VerificationStatus> status() async => VerificationStatus.notSubmitted;

  @override
  Future<Result<VerificationStatus, DataFailure>> submit(
    WorkerProfileDraft draft,
  ) async {
    submitted.add(draft);
    return result;
  }
}

final _session = Session(
  user: const AuthenticatedUser(subject: 'pro-1', roles: {ManoRole.provider}),
  accessToken: 'access-1',
  expiresAt: DateTime.now().add(const Duration(minutes: 5)),
);

final class _Redeemer implements WorkerReferralRedeemer {
  final redeemed = <ReferralCode>[];

  @override
  Future<Result<void, ReferralRedemptionFailure>> redeem(
    ReferralCode code,
  ) async {
    redeemed.add(code);
    return const Ok(null);
  }
}

({ProviderContainer c, ProviderOnboardingNotifier n}) _setUp([
  ProviderOnboardingRepository? repository,
  InMemorySessionRepository? session,
  WorkerReferralRedeemer? redeemer,
]) {
  final c = ProviderContainer.test(
    overrides: [
      inviteLinkSourceProvider.overrideWithValue(const NoInviteLinks()),
      installReferrerSourceProvider.overrideWithValue(
        const NoInstallReferrer(),
      ),
      workerReferralRedeemerProvider.overrideWithValue(
        redeemer ?? MockWorkerReferralRedeemer(),
      ),
      manoConfigProvider.overrideWithValue(
        const ManoConfig(
          gatewayGraphQlUrl: 'http://gw/graphql',
          appRole: ManoRole.provider,
        ),
      ),
      sessionRepositoryProvider.overrideWithValue(
        session ??
            InMemorySessionRepository(onSignUp: () async => Ok(_session)),
      ),
      providerOnboardingRepositoryProvider.overrideWithValue(
        repository ?? MockProviderOnboardingRepository(),
      ),
    ],
  );
  c.listen(providerOnboardingProvider, (_, _) {});
  return (c: c, n: c.read(providerOnboardingProvider.notifier));
}

const _toDocuments = [
  ProviderOnboardingStep.name,
  ProviderOnboardingStep.phone,
  ProviderOnboardingStep.zone,
  ProviderOnboardingStep.services,
  ProviderOnboardingStep.experience,
  ProviderOnboardingStep.bio,
  ProviderOnboardingStep.documents,
];

/// Email and password typed; the password step is on screen.
void _toPassword(ProviderOnboardingNotifier n) => n
  ..start()
  ..editEmail('pro@mano.co')
  ..next()
  ..editPassword('mano2026');

/// Tries to create the account; on success leaves the identity check for the name.
Future<void> _toName(ProviderOnboardingNotifier n) async {
  _toPassword(n);
  await n.createAccount();
  n.leaveIdentity();
}

Future<void> _answerAll(ProviderOnboardingNotifier n) async {
  await _toName(n);
  n
    ..editDisplayName('Ana Gómez')
    ..next()
    ..editPhone('300 123 4567')
    ..next()
    ..editWorkZone('Chapinero')
    ..next()
    ..toggleCategory(ServiceCategories.plumbing)
    ..toggleCategory(ServiceCategories.electrical)
    ..next()
    ..editExperience('5')
    ..next()
    ..editBio('Plomera con 5 años.')
    ..next();
}

ProviderOnboardingStep _step(ProviderContainer c) =>
    c.read(providerOnboardingProvider).step;

void main() {
  group('validation', () {
    test('display name must not be blank or one letter', () {
      expect(validateDisplayName('  '), ProfileProblem.empty);
      expect(validateDisplayName('A'), ProfileProblem.tooShort);
      expect(validateDisplayName('Ana'), isNull);
    });

    test('phone is a Colombian mobile, spaces and +57 allowed', () {
      expect(validatePhone(''), ProfileProblem.empty);
      expect(validatePhone('12345'), ProfileProblem.invalid);
      expect(validatePhone('200 123 4567'), ProfileProblem.invalid);
      expect(validatePhone('300abc4567'), ProfileProblem.invalid);
      expect(validatePhone('300 123 4567'), isNull);
      expect(validatePhone('+57 300-123-4567'), isNull);
    });

    test('work zone must not be blank', () {
      expect(validateWorkZone(' '), ProfileProblem.empty);
      expect(validateWorkZone('Chapinero'), isNull);
    });

    test('at least one service is needed', () {
      expect(validateServices(const []), ProfileProblem.empty);
      expect(validateServices(const ['plumbing']), isNull);
    });

    test('experience is whole years from 0 to 60', () {
      expect(validateExperience(''), ProfileProblem.empty);
      expect(validateExperience('abc'), ProfileProblem.invalid);
      expect(validateExperience('-1'), ProfileProblem.invalid);
      expect(validateExperience('61'), ProfileProblem.invalid);
      expect(validateExperience('0'), isNull);
      expect(validateExperience('12'), isNull);
    });

    test('bio is optional but bounded', () {
      expect(validateBio(''), isNull);
      expect(validateBio('a' * 281), ProfileProblem.invalid);
    });
  });

  test('starts on the intro step, idle and empty', () {
    final (:c, n: _) = _setUp();
    final s = c.read(providerOnboardingProvider);
    expect(s.step, ProviderOnboardingStep.intro);
    expect(s.status, isA<ProviderOnboardingIdle>());
    expect(s.attached, isEmpty);
    expect(s.inProgress, isFalse);
  });

  test('leaving the intro goes to the welcome, and back returns', () {
    final (:c, :n) = _setUp();

    n.leaveIntro();
    expect(_step(c), ProviderOnboardingStep.welcome);
    expect(c.read(providerOnboardingProvider).inProgress, isFalse);

    n.back();
    expect(_step(c), ProviderOnboardingStep.intro);
  });

  test('leaving the intro does nothing off the intro', () {
    final (:c, :n) = _setUp();
    n.startWithPhone();

    n.leaveIntro();

    expect(_step(c), ProviderOnboardingStep.signIn);
  });

  group('the account steps', () {
    test('start asks for the email first', () {
      final (:c, :n) = _setUp();
      n.start();
      expect(_step(c), ProviderOnboardingStep.email);
      expect(c.read(providerOnboardingProvider).inProgress, isTrue);
    });

    test('a malformed email stays and shows problems', () {
      final (:c, :n) = _setUp();
      n
        ..start()
        ..editEmail('pro@')
        ..next();
      expect(_step(c), ProviderOnboardingStep.email);
      expect(c.read(providerOnboardingProvider).showProblems, isTrue);
      expect(c.read(providerOnboardingProvider).stepComplete, isFalse);
    });

    test('a good email asks for a password', () {
      final (:c, :n) = _setUp();
      _toPassword(n);
      expect(_step(c), ProviderOnboardingStep.password);
    });

    test('the account steps count towards progress', () {
      final (:c, :n) = _setUp();
      n.start();
      final atEmail = c.read(providerOnboardingProvider).progress;
      _toPassword(n);
      expect(atEmail, greaterThan(0));
      expect(c.read(providerOnboardingProvider).progress, greaterThan(atEmail));
    });

    test('a weak password creates nothing and says why', () async {
      final session = InMemorySessionRepository(
        onSignUp: () async => Ok(_session),
      );
      final (:c, :n) = _setUp(null, session);
      _toPassword(n);
      n.editPassword('corta');

      await n.createAccount();

      expect(_step(c), ProviderOnboardingStep.password);
      expect(c.read(providerOnboardingProvider).showProblems, isTrue);
      expect(session.lastCredentials, isNull);
    });

    test(
      'creating the account signs up as a provider, then checks identity',
      () async {
        final session = InMemorySessionRepository(
          onSignUp: () async => Ok(_session),
        );
        final (:c, :n) = _setUp(null, session);
        _toPassword(n);

        await n.createAccount();

        expect(session.lastCredentials?.email, 'pro@mano.co');
        expect(session.lastSignUpRole, ManoRole.provider);
        expect(c.read(sessionProvider).value, isA<SignedIn>());
        expect(_step(c), ProviderOnboardingStep.identity);
        expect(c.read(providerOnboardingProvider).inProgress, isTrue);
      },
    );

    test('leaving the identity check asks the name', () async {
      final (:c, :n) = _setUp();
      _toPassword(n);
      await n.createAccount();

      n.leaveIdentity();

      expect(_step(c), ProviderOnboardingStep.name);
    });

    test('leaving the identity check is ignored on any other step', () {
      final (:c, :n) = _setUp();
      _toPassword(n);

      n.leaveIdentity();

      expect(_step(c), ProviderOnboardingStep.password);
    });

    test('the identity check does not go back to the password', () async {
      final (:c, :n) = _setUp();
      _toPassword(n);
      await n.createAccount();

      n.back();

      expect(_step(c), ProviderOnboardingStep.identity);
    });

    test('creating the account is observable while in flight', () async {
      final gate = Completer<Result<Session, AuthFailure>>();
      final (:c, :n) = _setUp(
        null,
        InMemorySessionRepository(onSignUp: () => gate.future),
      );
      _toPassword(n);

      final pending = n.createAccount();
      expect(
        c.read(providerOnboardingProvider).status,
        isA<ProviderOnboardingSubmitting>(),
      );

      gate.complete(Ok(_session));
      await pending;
      expect(
        c.read(providerOnboardingProvider).status,
        isA<ProviderOnboardingIdle>(),
      );
    });

    test('a taken email goes back to the email step, saying so', () async {
      final (:c, :n) = _setUp(
        null,
        InMemorySessionRepository(
          onSignUp: () async => const Err(EmailAlreadyRegistered()),
        ),
      );

      await _toName(n);

      final s = c.read(providerOnboardingProvider);
      expect(s.step, ProviderOnboardingStep.email);
      expect(
        (s.status as ProviderAccountRejected).failure,
        isA<EmailAlreadyRegistered>(),
      );
      expect(s.email, 'pro@mano.co');
      expect(
        (c.read(sessionProvider).value as SignedOut).lastFailure,
        isNull,
        reason: 'the step shows it; the welcome must not repeat it',
      );
    });

    test('an unreachable service stays on the password step', () async {
      final (:c, :n) = _setUp(
        null,
        InMemorySessionRepository(
          onSignUp: () async => const Err(AuthUnavailable()),
        ),
      );

      await _toName(n);

      final s = c.read(providerOnboardingProvider);
      expect(s.step, ProviderOnboardingStep.password);
      expect(
        (s.status as ProviderAccountRejected).failure,
        isA<AuthUnavailable>(),
      );
    });

    test('typing again clears the refusal', () async {
      final (:c, :n) = _setUp(
        null,
        InMemorySessionRepository(
          onSignUp: () async => const Err(AuthUnavailable()),
        ),
      );
      await _toName(n);

      n.editPassword('mano2027');

      expect(
        c.read(providerOnboardingProvider).status,
        isA<ProviderOnboardingIdle>(),
      );
    });

    test('"Ahora no" browses as a guest and leaves the onboarding', () async {
      final (:c, :n) = _setUp();
      await c.read(sessionProvider.future);
      n.start();

      n.browseAsGuest();

      expect(c.read(sessionProvider).value, isA<Guest>());
      expect(_step(c), ProviderOnboardingStep.welcome);
      expect(c.read(providerOnboardingProvider).inProgress, isFalse);
    });

    test('once the account exists, the name step does not go back', () async {
      final (:c, :n) = _setUp();
      await _toName(n);

      n.back();

      expect(_step(c), ProviderOnboardingStep.name);
    });

    test('back from the password step returns to the email', () {
      final (:c, :n) = _setUp();
      _toPassword(n);

      n.back();

      expect(_step(c), ProviderOnboardingStep.email);
    });
  });

  test('next on an unanswered question stays and shows problems', () async {
    final (:c, :n) = _setUp();
    await _toName(n);
    n.next();
    final s = c.read(providerOnboardingProvider);
    expect(s.step, ProviderOnboardingStep.name);
    expect(s.showProblems, isTrue);
  });

  test('each answer moves one question forward and hides problems', () async {
    final (:c, :n) = _setUp();
    await _toName(n);
    n
      ..next()
      ..editDisplayName('Ana Gómez')
      ..next();
    expect(_step(c), ProviderOnboardingStep.phone);
    expect(c.read(providerOnboardingProvider).showProblems, isFalse);

    n
      ..editPhone('12')
      ..next();
    expect(_step(c), ProviderOnboardingStep.phone);
  });

  test('the questions run in order up to documents', () async {
    final (:c, :n) = _setUp();
    final seen = <ProviderOnboardingStep>[];
    await _toName(n);
    seen.add(_step(c));
    n
      ..editDisplayName('Ana')
      ..next();
    seen.add(_step(c));
    n
      ..editPhone('3001234567')
      ..next();
    seen.add(_step(c));
    n
      ..editWorkZone('Chapinero')
      ..next();
    seen.add(_step(c));
    n
      ..toggleCategory(ServiceCategories.cleaning)
      ..next();
    seen.add(_step(c));
    n
      ..editExperience('0')
      ..next();
    seen.add(_step(c));
    n.next();
    seen.add(_step(c));
    expect(seen, _toDocuments);
  });

  test('services toggle on and off', () {
    final (:c, :n) = _setUp();
    n.toggleCategory(ServiceCategories.painting);
    expect(c.read(providerOnboardingProvider).categories, ['painting']);
    n.toggleCategory(ServiceCategories.painting);
    expect(c.read(providerOnboardingProvider).categories, isEmpty);
  });

  test('the bio can be skipped, clearing nothing it did not have', () async {
    final (:c, :n) = _setUp();
    await _toName(n);
    n
      ..editDisplayName('Ana')
      ..next()
      ..editPhone('3001234567')
      ..next()
      ..editWorkZone('Chapinero')
      ..next()
      ..toggleCategory(ServiceCategories.cleaning)
      ..next()
      ..editExperience('2')
      ..next()
      ..skip();
    expect(_step(c), ProviderOnboardingStep.documents);
    expect(c.read(providerOnboardingProvider).bio, isEmpty);
  });

  test('skip is ignored on required questions', () async {
    final (:c, :n) = _setUp();
    await _toName(n);
    n.skip();
    expect(_step(c), ProviderOnboardingStep.name);
  });

  test('firstName greets with the first word of the name', () {
    final (:c, :n) = _setUp();
    n.editDisplayName('  Ana Gómez ');
    expect(c.read(providerOnboardingProvider).firstName, 'Ana');
    expect(c.read(providerFirstNameProvider), 'Ana');
  });

  test('progress grows with each question', () async {
    final (:c, :n) = _setUp();
    await _toName(n);
    final first = c.read(providerOnboardingProvider).progress;
    n
      ..editDisplayName('Ana')
      ..next();
    expect(c.read(providerOnboardingProvider).progress, greaterThan(first));
    expect(first, greaterThan(0));
  });

  test(
    'documents are optional; the cédula goes through the identity check',
    () async {
      final (:c, :n) = _setUp();
      await _answerAll(n);
      expect(ProviderDocument.values, [ProviderDocument.certificates]);
      expect(c.read(providerOnboardingProvider).documentsComplete, isTrue);

      n.next();

      expect(_step(c), ProviderOnboardingStep.review);
    },
  );

  test('attach records a placeholder path per document', () {
    final (:c, :n) = _setUp();
    n.attach(ProviderDocument.certificates);
    expect(c.read(providerOnboardingProvider).attached, {
      ProviderDocument.certificates: 'placeholder://certificates',
    });
  });

  test('back walks every question and keeps the answers', () async {
    final (:c, :n) = _setUp();
    await _answerAll(n);
    n
      ..attach(ProviderDocument.certificates)
      ..next()
      ..back();
    expect(_step(c), ProviderOnboardingStep.documents);
    for (final expected in _toDocuments.reversed.skip(1)) {
      n.back();
      expect(_step(c), expected);
    }
    final s = c.read(providerOnboardingProvider);
    expect(s.displayName, 'Ana Gómez');
    expect(s.categories, hasLength(2));
    expect(s.attached, hasLength(1));
    n.back();
    expect(
      _step(c),
      ProviderOnboardingStep.name,
      reason:
          'the account exists; the first question is as far back as it goes',
    );
  });

  test('submit sends the draft and lands on pending', () async {
    final repo = _RecordingOnboarding(const Ok(VerificationStatus.pending));
    final (:c, :n) = _setUp(repo);
    await _answerAll(n);
    n.next();

    await n.submit();

    expect(
      repo.submitted.single,
      const WorkerProfileDraft(
        displayName: 'Ana Gómez',
        phone: '3001234567',
        workZone: 'Chapinero',
        categories: ['plumbing', 'electrical'],
        yearsExperience: 5,
        bio: 'Plomera con 5 años.',
      ),
    );
    expect(_step(c), ProviderOnboardingStep.pending);
  });

  test('a submitted profile redeems the colleague code kept for it', () async {
    final redeemer = _Redeemer();
    final (:c, :n) = _setUp(
      _RecordingOnboarding(const Ok(VerificationStatus.pending)),
      null,
      redeemer,
    );
    c.listen(referralInviteProvider, (_, _) {});
    final code = ReferralCode.parse('RP-bb2cde6b')!;
    c.read(referralInviteProvider.notifier).keep(code);
    await _answerAll(n);
    n.next();

    await n.submit();
    await Future<void>.delayed(Duration.zero);

    expect(redeemer.redeemed, [code]);
    expect(_step(c), ProviderOnboardingStep.pending);
  });

  test('a failed submit redeems nothing yet', () async {
    final redeemer = _Redeemer();
    final (:c, :n) = _setUp(
      _RecordingOnboarding(const Err(DataUnavailable())),
      null,
      redeemer,
    );
    c.listen(referralInviteProvider, (_, _) {});
    c
        .read(referralInviteProvider.notifier)
        .keep(ReferralCode.parse('RP-bb2cde6b')!);
    await _answerAll(n);
    n.next();

    await n.submit();

    expect(redeemer.redeemed, isEmpty);
    expect(c.read(referralInviteProvider).code, isNotNull);
  });

  test('finishing leaves the onboarding but keeps the name to greet', () async {
    final (:c, :n) = _setUp(
      _RecordingOnboarding(const Ok(VerificationStatus.pending)),
    );
    await _answerAll(n);
    n.next();
    await n.submit();

    n.finish();

    expect(c.read(providerOnboardingProvider).inProgress, isFalse);
    expect(c.read(providerFirstNameProvider), 'Ana');
  });

  test('a failed submit keeps the data and reports the failure', () async {
    final repo = _RecordingOnboarding(const Err(DataUnavailable()));
    final (:c, :n) = _setUp(repo);
    await _answerAll(n);
    n.next();

    await n.submit();

    final s = c.read(providerOnboardingProvider);
    expect(s.step, ProviderOnboardingStep.review);
    expect(s.status, isA<ProviderOnboardingFailed>());
    expect(s.displayName, 'Ana Gómez');

    n.acknowledgeFailure();
    expect(
      c.read(providerOnboardingProvider).status,
      isA<ProviderOnboardingIdle>(),
    );
  });

  test('submit is ignored off the review step', () async {
    final repo = _RecordingOnboarding(const Ok(VerificationStatus.pending));
    final (c: _, :n) = _setUp(repo);
    await n.submit();
    expect(repo.submitted, isEmpty);
  });

  group('phone and social sign-in', () {
    Session signedIn({required bool isNew}) => Session(
      user: _session.user,
      accessToken: _session.accessToken,
      expiresAt: _session.expiresAt,
      isNewAccount: isNew,
    );

    test('the welcome opens the phone sign-in, and back returns', () {
      final (:c, :n) = _setUp();

      n.startWithPhone();
      expect(_step(c), ProviderOnboardingStep.signIn);
      expect(c.read(providerOnboardingProvider).inProgress, isTrue);

      n.back();
      expect(_step(c), ProviderOnboardingStep.welcome);
    });

    test('a new account goes to the identity check, its phone kept', () async {
      final (:c, :n) = _setUp();
      await c.read(sessionProvider.future);
      n.startWithPhone();

      n.enter(signedIn(isNew: true), phone: '+573001234567');

      expect(c.read(sessionProvider).value, isA<SignedIn>());
      expect(_step(c), ProviderOnboardingStep.identity);
      expect(c.read(providerOnboardingProvider).phone, '3001234567');
      expect(c.read(providerOnboardingProvider).inProgress, isTrue);
    });

    test('a number from elsewhere is kept whole, dial code and all', () async {
      final (:c, :n) = _setUp();
      await c.read(sessionProvider.future);
      n.startWithPhone();

      n.enter(signedIn(isNew: true), phone: '+525512345678');

      expect(c.read(providerOnboardingProvider).phone, '+525512345678');
    });

    test('a phone sign-up is not asked its number again', () async {
      final (:c, :n) = _setUp();
      await c.read(sessionProvider.future);
      n
        ..startWithPhone()
        ..enter(signedIn(isNew: true), phone: '+573001234567')
        ..leaveIdentity()
        ..editDisplayName('Ana Gómez')
        ..next();

      expect(_step(c), ProviderOnboardingStep.zone);
      n.back();
      expect(_step(c), ProviderOnboardingStep.name);
      expect(c.read(providerOnboardingProvider).draft.phone, '3001234567');
    });

    test('a sign-up with no number still gets the phone question', () async {
      final (:c, :n) = _setUp();
      await c.read(sessionProvider.future);
      n
        ..enter(signedIn(isNew: true))
        ..leaveIdentity()
        ..editDisplayName('Ana Gómez')
        ..next();

      expect(_step(c), ProviderOnboardingStep.phone);
    });

    test('a returning account leaves the onboarding for the shell', () async {
      final (:c, :n) = _setUp();
      await c.read(sessionProvider.future);
      n.startWithPhone();

      n.enter(signedIn(isNew: false));

      expect(c.read(sessionProvider).value, isA<SignedIn>());
      expect(c.read(providerOnboardingProvider).inProgress, isFalse);
    });

    test('email sign-up stays one step past the phone screen', () {
      final (:c, :n) = _setUp();
      n
        ..startWithPhone()
        ..start();

      expect(_step(c), ProviderOnboardingStep.email);
      n.back();
      expect(_step(c), ProviderOnboardingStep.signIn);
    });
  });
}
