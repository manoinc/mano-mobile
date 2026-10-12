import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../marketplace_providers.dart';
import 'provider_profile_validation.dart';

enum ProviderOnboardingStep {
  welcome,
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

enum ProviderDocument {
  idFront('id-front', required: true),
  idBack('id-back', required: true),
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

const _questions = [
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

  /// Whether the current question can be answered as it stands.
  bool get stepComplete => switch (step) {
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
const _flow = [
  ProviderOnboardingStep.welcome,
  ..._questions,
  ProviderOnboardingStep.review,
  ProviderOnboardingStep.pending,
];

final class ProviderOnboardingNotifier
    extends Notifier<ProviderOnboardingState> {
  @override
  ProviderOnboardingState build() => const ProviderOnboardingState();

  void start() => _goTo(ProviderOnboardingStep.name);

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
    if (!state.stepComplete) {
      state = state.copyWith(showProblems: true);
      return;
    }
    final i = _flow.indexOf(state.step);
    if (i >= 0 && i < _flow.length - 1) _goTo(_flow[i + 1]);
  }

  /// Passes over the optional bio without answering it.
  void skip() {
    if (state.step != ProviderOnboardingStep.bio) return;
    state = state.copyWith(bio: '');
    next();
  }

  void back() {
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
