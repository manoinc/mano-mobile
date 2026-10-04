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

void _fillProfile(ProviderOnboardingNotifier n) => n
  ..editDisplayName('Ana Gómez')
  ..editPhone('300 123 4567')
  ..editWorkZone('Chapinero');

void _attachIds(ProviderOnboardingNotifier n) => n
  ..attach(ProviderDocument.idFront)
  ..attach(ProviderDocument.idBack);

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
  });

  test('starts on the welcome step, idle and empty', () {
    final (:c, n: _) = _setUp();
    final s = c.read(providerOnboardingProvider);
    expect(s.step, ProviderOnboardingStep.welcome);
    expect(s.status, isA<ProviderOnboardingIdle>());
    expect(s.attached, isEmpty);
  });

  test('start moves to the profile step', () {
    final (:c, :n) = _setUp();
    n.start();
    expect(
      c.read(providerOnboardingProvider).step,
      ProviderOnboardingStep.profile,
    );
  });

  test('next on an invalid profile stays and shows problems', () {
    final (:c, :n) = _setUp();
    n
      ..start()
      ..next();
    final s = c.read(providerOnboardingProvider);
    expect(s.step, ProviderOnboardingStep.profile);
    expect(s.showProblems, isTrue);
  });

  test('next on a valid profile moves to documents and hides problems', () {
    final (:c, :n) = _setUp();
    n
      ..start()
      ..next();
    _fillProfile(n);
    n.next();
    final s = c.read(providerOnboardingProvider);
    expect(s.step, ProviderOnboardingStep.documents);
    expect(s.showProblems, isFalse);
  });

  test('documents need both ID sides before moving on', () {
    final (:c, :n) = _setUp();
    n.start();
    _fillProfile(n);
    n
      ..next()
      ..attach(ProviderDocument.idFront)
      ..next();
    expect(c.read(providerOnboardingProvider).documentsComplete, isFalse);
    expect(
      c.read(providerOnboardingProvider).step,
      ProviderOnboardingStep.documents,
    );

    n
      ..attach(ProviderDocument.idBack)
      ..next();
    expect(
      c.read(providerOnboardingProvider).step,
      ProviderOnboardingStep.review,
    );
  });

  test('attach records a placeholder path per document', () {
    final (:c, :n) = _setUp();
    n.attach(ProviderDocument.certificates);
    expect(c.read(providerOnboardingProvider).attached, {
      ProviderDocument.certificates: 'placeholder://certificates',
    });
  });

  test('back walks the steps and keeps the draft', () {
    final (:c, :n) = _setUp();
    n.start();
    _fillProfile(n);
    n.next();
    _attachIds(n);
    n
      ..next()
      ..back();
    expect(
      c.read(providerOnboardingProvider).step,
      ProviderOnboardingStep.documents,
    );
    n.back();
    final s = c.read(providerOnboardingProvider);
    expect(s.step, ProviderOnboardingStep.profile);
    expect(s.displayName, 'Ana Gómez');
    expect(s.attached, hasLength(2));
    n.back();
    expect(
      c.read(providerOnboardingProvider).step,
      ProviderOnboardingStep.welcome,
    );
  });

  test('submit sends the draft and lands on pending', () async {
    final repo = _RecordingOnboarding(const Ok(VerificationStatus.pending));
    final (:c, :n) = _setUp(repo);
    n.start();
    _fillProfile(n);
    n.next();
    _attachIds(n);
    n.next();

    await n.submit();

    expect(
      repo.submitted.single,
      const WorkerProfileDraft(
        displayName: 'Ana Gómez',
        phone: '3001234567',
        workZone: 'Chapinero',
        documentPaths: ['placeholder://id-front', 'placeholder://id-back'],
      ),
    );
    expect(
      c.read(providerOnboardingProvider).step,
      ProviderOnboardingStep.pending,
    );
  });

  test('a failed submit keeps the data and reports the failure', () async {
    final repo = _RecordingOnboarding(const Err(DataUnavailable()));
    final (:c, :n) = _setUp(repo);
    n.start();
    _fillProfile(n);
    n.next();
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
