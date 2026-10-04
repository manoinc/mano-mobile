import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../marketplace_providers.dart';
import 'provider_profile_validation.dart';

enum ProviderOnboardingStep { welcome, profile, documents, review, pending }

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

final class ProviderOnboardingState {
  const ProviderOnboardingState({
    this.step = ProviderOnboardingStep.welcome,
    this.displayName = '',
    this.phone = '',
    this.workZone = '',
    this.attached = const {},
    this.showProblems = false,
    this.status = const ProviderOnboardingIdle(),
  });

  final ProviderOnboardingStep step;
  final String displayName;
  final String phone;
  final String workZone;

  /// Attached documents and their (placeholder) local paths.
  final Map<ProviderDocument, String> attached;

  /// Errors appear on the first refused Continuar, not on the first keystroke.
  final bool showProblems;

  final ProviderOnboardingStatus status;

  bool get profileComplete =>
      validateDisplayName(displayName) == null &&
      validatePhone(phone) == null &&
      validateWorkZone(workZone) == null;

  bool get documentsComplete => ProviderDocument.values
      .where((d) => d.required)
      .every(attached.containsKey);

  WorkerProfileDraft get draft => WorkerProfileDraft(
    displayName: displayName.trim(),
    phone: normalizePhone(phone) ?? phone.trim(),
    workZone: workZone.trim(),
    documentPaths: [
      for (final d in ProviderDocument.values)
        ?attached[d],
    ],
  );

  ProviderOnboardingState copyWith({
    ProviderOnboardingStep? step,
    String? displayName,
    String? phone,
    String? workZone,
    Map<ProviderDocument, String>? attached,
    bool? showProblems,
    ProviderOnboardingStatus? status,
  }) => ProviderOnboardingState(
    step: step ?? this.step,
    displayName: displayName ?? this.displayName,
    phone: phone ?? this.phone,
    workZone: workZone ?? this.workZone,
    attached: attached ?? this.attached,
    showProblems: showProblems ?? this.showProblems,
    status: status ?? this.status,
  );
}

/// A professional's sign-up: profile, documents, then submission for review.
final class ProviderOnboardingNotifier
    extends Notifier<ProviderOnboardingState> {
  @override
  ProviderOnboardingState build() => const ProviderOnboardingState();

  void start() => _goTo(ProviderOnboardingStep.profile);

  void editDisplayName(String value) =>
      state = state.copyWith(displayName: value);

  void editPhone(String value) => state = state.copyWith(phone: value);

  void editWorkZone(String value) => state = state.copyWith(workZone: value);

  // No picker yet, so a fixed placeholder stands in for the chosen file.
  void attach(ProviderDocument document) => state = state.copyWith(
    attached: {...state.attached, document: 'placeholder://${document.slug}'},
  );

  /// Advances if the current step is complete; otherwise starts showing why not.
  void next() {
    final next = switch (state.step) {
      ProviderOnboardingStep.profile when state.profileComplete =>
        ProviderOnboardingStep.documents,
      ProviderOnboardingStep.documents when state.documentsComplete =>
        ProviderOnboardingStep.review,
      _ => null,
    };
    if (next == null) {
      state = state.copyWith(showProblems: true);
    } else {
      _goTo(next);
    }
  }

  void back() {
    final previous = switch (state.step) {
      ProviderOnboardingStep.profile => ProviderOnboardingStep.welcome,
      ProviderOnboardingStep.documents => ProviderOnboardingStep.profile,
      ProviderOnboardingStep.review => ProviderOnboardingStep.documents,
      ProviderOnboardingStep.welcome || ProviderOnboardingStep.pending => null,
    };
    if (previous != null) _goTo(previous);
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
