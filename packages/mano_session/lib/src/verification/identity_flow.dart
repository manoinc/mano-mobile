import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../media/media_providers.dart';
import 'identity_verification_providers.dart';

/// The screens of the identity check, in the order they are walked.
enum IdentityFlowStep {
  loading,
  intro,
  cedulaFront,
  cedulaBack,
  selfie,
  review,
  pending,
  approved,
  rejected;

  /// The photo this step takes, if it takes one.
  IdentityDocumentKind? get kind => switch (this) {
    cedulaFront => IdentityDocumentKind.cedulaFront,
    cedulaBack => IdentityDocumentKind.cedulaBack,
    selfie => IdentityDocumentKind.selfie,
    _ => null,
  };

  static IdentityFlowStep of(IdentityDocumentKind kind) => switch (kind) {
    IdentityDocumentKind.cedulaFront => cedulaFront,
    IdentityDocumentKind.cedulaBack => cedulaBack,
    IdentityDocumentKind.selfie => selfie,
  };
}

const _walked = [
  IdentityFlowStep.intro,
  IdentityFlowStep.cedulaFront,
  IdentityFlowStep.cedulaBack,
  IdentityFlowStep.selfie,
  IdentityFlowStep.review,
];

final class IdentityFlowState {
  const IdentityFlowState({
    this.step = IdentityFlowStep.loading,
    this.photos = const {},
    this.busy = false,
    this.retaking = false,
    this.failure,
    this.rejection,
  });

  final IdentityFlowStep step;

  /// Kept on the device for the review thumbnails.
  final Map<IdentityDocumentKind, PickedImage> photos;

  final bool busy;

  /// A photo is being taken again from the review, which it returns to.
  final bool retaking;

  /// The last action's refusal; any later change clears it.
  final DataFailure? failure;

  /// Why the checker refused, while [step] is rejected.
  final String? rejection;

  /// 0..1 across intro to review; null on the screens around them.
  double? get progress {
    final i = _walked.indexOf(step);
    return i < 0 ? null : (i + 1) / _walked.length;
  }

  IdentityFlowState copyWith({
    IdentityFlowStep? step,
    Map<IdentityDocumentKind, PickedImage>? photos,
    bool? busy,
    bool? retaking,
    DataFailure? failure,
    String? rejection,
  }) => IdentityFlowState(
    step: step ?? this.step,
    photos: photos ?? this.photos,
    busy: busy ?? this.busy,
    retaking: retaking ?? this.retaking,
    failure: failure,
    rejection: rejection ?? this.rejection,
  );
}

/// Walks a person through the cédula and selfie photos, then sends them.
final class IdentityFlowNotifier extends Notifier<IdentityFlowState> {
  @override
  IdentityFlowState build() {
    Future.microtask(refresh);
    return const IdentityFlowState();
  }

  IdentityVerificationPort get _port => ref.read(identityVerificationProvider);

  /// Asks the checker where things stand and opens the matching screen.
  Future<void> refresh() async {
    final result = await _port.status();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => _showing(value),
      Err(:final failure) => state.copyWith(
        step: IdentityFlowStep.intro,
        failure: failure,
      ),
    };
  }

  void begin() {
    if (state.step == IdentityFlowStep.intro) _goTo(_nextMissing());
  }

  /// Takes the current step's photo with the camera and sends it.
  Future<void> capture() async {
    final kind = state.step.kind;
    if (kind == null || state.busy) return;
    final image = await ref.read(mediaPickerProvider).pick(PhotoSource.camera);
    if (image == null || !ref.mounted) return;
    state = state.copyWith(busy: true);
    final result = await _port.submit(kind, image);
    if (!ref.mounted) return;
    if (result case Err(:final failure)) {
      state = state.copyWith(busy: false, failure: failure);
      return;
    }
    final photos = {...state.photos, kind: image};
    state = state.copyWith(photos: photos, busy: false);
    _goTo(state.retaking ? IdentityFlowStep.review : _nextMissing());
  }

  void retake(IdentityDocumentKind kind) {
    if (state.step != IdentityFlowStep.review) return;
    state = state.copyWith(step: IdentityFlowStep.of(kind), retaking: true);
  }

  /// Sends every photo for review.
  Future<void> send() async {
    if (state.step != IdentityFlowStep.review || state.busy) return;
    state = state.copyWith(busy: true);
    final result = await _port.finish();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => _showing(value).copyWith(busy: false),
      Err(:final failure) => state.copyWith(busy: false, failure: failure),
    };
  }

  /// After a refusal, every photo is taken again.
  void retry() {
    if (state.step != IdentityFlowStep.rejected) return;
    state = const IdentityFlowState(step: IdentityFlowStep.cedulaFront);
  }

  void back() {
    if (state.busy) return;
    if (state.retaking) return _goTo(IdentityFlowStep.review);
    final i = _walked.indexOf(state.step);
    if (i > 0) _goTo(_walked[i - 1]);
  }

  void acknowledgeFailure() => state = state.copyWith();

  IdentityFlowStep _nextMissing() {
    for (final kind in IdentityDocumentKind.values) {
      if (!state.photos.containsKey(kind)) return IdentityFlowStep.of(kind);
    }
    return IdentityFlowStep.review;
  }

  IdentityFlowState _showing(IdentityCheckStatus status) => switch (status) {
    IdentityCheckInProgress() => state.copyWith(step: IdentityFlowStep.intro),
    IdentityCheckPending() => state.copyWith(step: IdentityFlowStep.pending),
    IdentityCheckApproved() => state.copyWith(step: IdentityFlowStep.approved),
    IdentityCheckRejected(:final reason) => state.copyWith(
      step: IdentityFlowStep.rejected,
      rejection: reason,
    ),
  };

  void _goTo(IdentityFlowStep step) =>
      state = state.copyWith(step: step, retaking: false);
}

final identityFlowProvider =
    NotifierProvider<IdentityFlowNotifier, IdentityFlowState>(
      IdentityFlowNotifier.new,
    );

/// Whether the identity check has come back approved.
final identityVerifiedProvider = Provider<bool>(
  (ref) => ref.watch(
    identityFlowProvider.select((s) => s.step == IdentityFlowStep.approved),
  ),
);
