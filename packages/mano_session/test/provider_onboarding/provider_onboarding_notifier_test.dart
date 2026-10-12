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

({ProviderContainer c, ProviderOnboardingNotifier n}) _setUp([
  ProviderOnboardingRepository? repository,
]) {
  final c = ProviderContainer.test(
    overrides: [
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

void _answerAll(ProviderOnboardingNotifier n) {
  n
    ..start()
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

void _attachIds(ProviderOnboardingNotifier n) => n
  ..attach(ProviderDocument.idFront)
  ..attach(ProviderDocument.idBack);

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

  test('starts on the welcome step, idle and empty', () {
    final (:c, n: _) = _setUp();
    final s = c.read(providerOnboardingProvider);
    expect(s.step, ProviderOnboardingStep.welcome);
    expect(s.status, isA<ProviderOnboardingIdle>());
    expect(s.attached, isEmpty);
  });

  test('start moves to the name question', () {
    final (:c, :n) = _setUp();
    n.start();
    expect(_step(c), ProviderOnboardingStep.name);
  });

  test('next on an unanswered question stays and shows problems', () {
    final (:c, :n) = _setUp();
    n
      ..start()
      ..next();
    final s = c.read(providerOnboardingProvider);
    expect(s.step, ProviderOnboardingStep.name);
    expect(s.showProblems, isTrue);
  });

  test('each answer moves one question forward and hides problems', () {
    final (:c, :n) = _setUp();
    n
      ..start()
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

  test('the questions run in order up to documents', () {
    final (:c, :n) = _setUp();
    final seen = <ProviderOnboardingStep>[];
    n.start();
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

  test('the bio can be skipped, clearing nothing it did not have', () {
    final (:c, :n) = _setUp();
    n
      ..start()
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

  test('skip is ignored on required questions', () {
    final (:c, :n) = _setUp();
    n
      ..start()
      ..skip();
    expect(_step(c), ProviderOnboardingStep.name);
  });

  test('firstName greets with the first word of the name', () {
    final (:c, :n) = _setUp();
    n.editDisplayName('  Ana Gómez ');
    expect(c.read(providerOnboardingProvider).firstName, 'Ana');
    expect(c.read(providerFirstNameProvider), 'Ana');
  });

  test('progress grows with each question', () {
    final (:c, :n) = _setUp();
    n.start();
    final first = c.read(providerOnboardingProvider).progress;
    n
      ..editDisplayName('Ana')
      ..next();
    expect(c.read(providerOnboardingProvider).progress, greaterThan(first));
    expect(first, greaterThan(0));
  });

  test('documents need both ID sides before moving on', () {
    final (:c, :n) = _setUp();
    _answerAll(n);
    n
      ..attach(ProviderDocument.idFront)
      ..next();
    expect(c.read(providerOnboardingProvider).documentsComplete, isFalse);
    expect(_step(c), ProviderOnboardingStep.documents);

    n
      ..attach(ProviderDocument.idBack)
      ..next();
    expect(_step(c), ProviderOnboardingStep.review);
  });

  test('attach records a placeholder path per document', () {
    final (:c, :n) = _setUp();
    n.attach(ProviderDocument.certificates);
    expect(c.read(providerOnboardingProvider).attached, {
      ProviderDocument.certificates: 'placeholder://certificates',
    });
  });

  test('back walks every question and keeps the answers', () {
    final (:c, :n) = _setUp();
    _answerAll(n);
    _attachIds(n);
    n
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
    expect(s.attached, hasLength(2));
    n.back();
    expect(_step(c), ProviderOnboardingStep.welcome);
  });

  test('submit sends the draft and lands on pending', () async {
    final repo = _RecordingOnboarding(const Ok(VerificationStatus.pending));
    final (:c, :n) = _setUp(repo);
    _answerAll(n);
    _attachIds(n);
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
        documentPaths: ['placeholder://id-front', 'placeholder://id-back'],
      ),
    );
    expect(_step(c), ProviderOnboardingStep.pending);
  });

  test('a failed submit keeps the data and reports the failure', () async {
    final repo = _RecordingOnboarding(const Err(DataUnavailable()));
    final (:c, :n) = _setUp(repo);
    _answerAll(n);
    _attachIds(n);
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
}
