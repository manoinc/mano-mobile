import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../marketplace_providers.dart';
import '../session_notifier.dart';
import 'provider_profile_validation.dart';

/// The account is created on leaving [password], so [identity] onward is signed in.
enum ProviderOnboardingStep {
  welcome,
  email,
  password,
  identity,
  name,
  phone,
  zone,
  services,
  experience,
  bio,
  documents,
  review,
  pending,
}

/// Supporting papers; the cédula goes through the identity check instead.
enum ProviderDocument {
  certificates('certificates', required: false);

  const ProviderDocument(this.slug, {required this.required});

  final String slug;
  final bool required;
}

sealed class ProviderOnboardingStatus {
  const ProviderOnboardingStatus();
}

final class ProviderOnboardingIdle extends ProviderOnboardingStatus {
  const ProviderOnboardingIdle();
}

final class ProviderOnboardingSubmitting extends ProviderOnboardingStatus {
  const ProviderOnboardingSubmitting();
}

final class ProviderOnboardingFailed extends ProviderOnboardingStatus {
  const ProviderOnboardingFailed(this.failure);

  final DataFailure failure;
}

/// Creating the account was refused; the step shows why, inline.
final class ProviderAccountRejected extends ProviderOnboardingStatus {
  const ProviderAccountRejected(this.failure);

  final AuthFailure failure;
}

const _questions = [
  ProviderOnboardingStep.email,
  ProviderOnboardingStep.password,
  ProviderOnboardingStep.name,
  ProviderOnboardingStep.phone,
  ProviderOnboardingStep.zone,
  ProviderOnboardingStep.services,
  ProviderOnboardingStep.experience,
  ProviderOnboardingStep.bio,
  ProviderOnboardingStep.documents,
];

final class ProviderOnboardingState {
  const ProviderOnboardingState({
    this.step = ProviderOnboardingStep.welcome,
    this.email = '',
    this.password = '',
    this.finished = false,
    this.displayName = '',
    this.phone = '',
    this.workZone = '',
    this.categories = const [],
    this.experience = '',
    this.bio = '',
    this.attached = const {},
    this.showProblems = false,
    this.status = const ProviderOnboardingIdle(),
  });

  final ProviderOnboardingStep step;

  /// The new account's credentials, kept out of the profile draft.
  final String email;
  final String password;

  /// Set once the pending step is left for the app.
  final bool finished;

  final String displayName;
  final String phone;
  final String workZone;
  final List<String> categories;

  /// Years as typed; parsed only when the draft is built.
  final String experience;
  final String bio;

  /// Attached documents and their (placeholder) local paths.
  final Map<ProviderDocument, String> attached;

  /// Errors appear on the first refused Continuar, not on the first keystroke.
  final bool showProblems;

  final ProviderOnboardingStatus status;

  /// What the app greets with: the first word of the name.
  String get firstName {
    final trimmed = displayName.trim();
    final space = trimmed.indexOf(' ');
    return space < 0 ? trimmed : trimmed.substring(0, space);
  }

  /// Whether the onboarding still owns the screen, signed in or not.
  bool get inProgress => step != ProviderOnboardingStep.welcome && !finished;

  /// Whether the current question can be answered as it stands.
  bool get stepComplete => switch (step) {
    ProviderOnboardingStep.email => validateEmail(email) == null,
    ProviderOnboardingStep.password => validatePassword(password) == null,
    ProviderOnboardingStep.name => validateDisplayName(displayName) == null,
    ProviderOnboardingStep.phone => validatePhone(phone) == null,
    ProviderOnboardingStep.zone => validateWorkZone(workZone) == null,
    ProviderOnboardingStep.services => validateServices(categories) == null,
    ProviderOnboardingStep.experience => validateExperience(experience) == null,
    ProviderOnboardingStep.bio => validateBio(bio) == null,
    ProviderOnboardingStep.documents => documentsComplete,
    _ => true,
  };

  /// Position among the questions as a 0..1 fraction; zero off them.
  double get progress {
    final i = _questions.indexOf(step);
    return i < 0 ? 0 : (i + 1) / _questions.length;
  }

  bool get documentsComplete => ProviderDocument.values
      .where((d) => d.required)
      .every(attached.containsKey);

  WorkerProfileDraft get draft => WorkerProfileDraft(
    displayName: displayName.trim(),
    phone: normalizePhone(phone) ?? phone.trim(),
    workZone: workZone.trim(),
    categories: categories,
    yearsExperience: int.tryParse(experience.trim()) ?? 0,
    bio: bio.trim(),
    documentPaths: [for (final d in ProviderDocument.values) ?attached[d]],
  );

  ProviderOnboardingState copyWith({
    ProviderOnboardingStep? step,
    String? email,
    String? password,
    bool? finished,
    String? displayName,
    String? phone,
    String? workZone,
    List<String>? categories,
    String? experience,
    String? bio,
    Map<ProviderDocument, String>? attached,
    bool? showProblems,
    ProviderOnboardingStatus? status,
  }) => ProviderOnboardingState(
    step: step ?? this.step,
    email: email ?? this.email,
    password: password ?? this.password,
    finished: finished ?? this.finished,
    displayName: displayName ?? this.displayName,
    phone: phone ?? this.phone,
    workZone: workZone ?? this.workZone,
    categories: categories ?? this.categories,
    experience: experience ?? this.experience,
    bio: bio ?? this.bio,
    attached: attached ?? this.attached,
    showProblems: showProblems ?? this.showProblems,
    status: status ?? this.status,
  );
}

/// A professional's sign-up: one question at a time, then review.
const _flow = ProviderOnboardingStep.values;

final class ProviderOnboardingNotifier
    extends Notifier<ProviderOnboardingState> {
  @override
  ProviderOnboardingState build() => const ProviderOnboardingState();

  void start() => _goTo(ProviderOnboardingStep.email);

  void editEmail(String value) => _editAccount(email: value);

  void editPassword(String value) => _editAccount(password: value);

  /// Signs the new account up from the password step; on success the questions begin.
  Future<void> createAccount() async {
    if (state.step != ProviderOnboardingStep.password ||
        state.status is ProviderOnboardingSubmitting) {
      return;
    }
    if (!state.stepComplete) {
      state = state.copyWith(showProblems: true);
      return;
    }
    state = state.copyWith(status: const ProviderOnboardingSubmitting());
    final session = ref.read(sessionProvider.notifier);
    final failure = await session.signUp(
      Credentials(email: state.email, password: state.password),
    );
    if (!ref.mounted) return;
    if (failure == null) {
      _goTo(ProviderOnboardingStep.identity);
      return;
    }
    // Shown on the step itself; the welcome must not repeat it.
    session.acknowledgeFailure();
    state = state.copyWith(
      step: failure is EmailAlreadyRegistered
          ? ProviderOnboardingStep.email
          : ProviderOnboardingStep.password,
      status: ProviderAccountRejected(failure),
    );
  }

  /// "Ahora no": into the app without an account.
  void browseAsGuest() {
    ref.read(sessionProvider.notifier).browseAsGuest();
    state = const ProviderOnboardingState();
  }

  /// Leaves the pending step for the app, keeping the answers for greetings.
  void finish() => state = state.copyWith(finished: true);

  void _editAccount({String? email, String? password}) =>
      state = state.copyWith(
        email: email,
        password: password,
        status: state.status is ProviderAccountRejected
            ? const ProviderOnboardingIdle()
            : null,
      );

  void editDisplayName(String value) =>
      state = state.copyWith(displayName: value);

  void editPhone(String value) => state = state.copyWith(phone: value);

  void editWorkZone(String value) => state = state.copyWith(workZone: value);

  void toggleCategory(String id) {
    final chosen = [...state.categories];
    if (!chosen.remove(id)) chosen.add(id);
    state = state.copyWith(categories: chosen);
  }

  void editExperience(String value) =>
      state = state.copyWith(experience: value);

  void editBio(String value) => state = state.copyWith(bio: value);

  // No picker yet, so a fixed placeholder stands in for the chosen file.
  void attach(ProviderDocument document) => state = state.copyWith(
    attached: {...state.attached, document: 'placeholder://${document.slug}'},
  );

  /// Advances if the current question is answered; otherwise shows why not.
  void next() {
    // The password step leaves through createAccount.
    if (state.step == ProviderOnboardingStep.password) return;
    if (!state.stepComplete) {
      state = state.copyWith(showProblems: true);
      return;
    }
    final i = _flow.indexOf(state.step);
    if (i >= 0 && i < _flow.length - 1) _goTo(_flow[i + 1]);
  }

  /// Leaves the identity check, done or put off, for the first question.
  void leaveIdentity() {
    if (state.step == ProviderOnboardingStep.identity) {
      _goTo(ProviderOnboardingStep.name);
    }
  }

  /// Passes over the optional bio without answering it.
  void skip() {
    if (state.step != ProviderOnboardingStep.bio) return;
    state = state.copyWith(bio: '');
    next();
  }

  void back() {
    // The account already exists; there is no going back to create it.
    if (state.step == ProviderOnboardingStep.identity ||
        state.step == ProviderOnboardingStep.name) {
      return;
    }
    final i = _flow.indexOf(state.step);
    if (i > 0 && state.step != ProviderOnboardingStep.pending) {
      _goTo(_flow[i - 1]);
    }
  }

  void acknowledgeFailure() {
    if (state.status is ProviderOnboardingFailed) {
      state = state.copyWith(status: const ProviderOnboardingIdle());
    }
  }

  Future<void> submit() async {
    if (state.step != ProviderOnboardingStep.review ||
        state.status is ProviderOnboardingSubmitting) {
      return;
    }
    state = state.copyWith(status: const ProviderOnboardingSubmitting());
    final result = await ref
        .read(providerOnboardingRepositoryProvider)
        .submit(state.draft);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => state.copyWith(
        step: ProviderOnboardingStep.pending,
        status: const ProviderOnboardingIdle(),
      ),
      Err(:final failure) => state.copyWith(
        status: ProviderOnboardingFailed(failure),
      ),
    };
  }

  void _goTo(ProviderOnboardingStep step) => state = state.copyWith(
    step: step,
    showProblems: false,
    status: const ProviderOnboardingIdle(),
  );
}

final providerOnboardingProvider =
    NotifierProvider<ProviderOnboardingNotifier, ProviderOnboardingState>(
      ProviderOnboardingNotifier.new,
    );

/// The first name the professional gave, for greetings ("Hola, Ana").
final providerFirstNameProvider = Provider<String>(
  (ref) => ref.watch(providerOnboardingProvider.select((s) => s.firstName)),
);
