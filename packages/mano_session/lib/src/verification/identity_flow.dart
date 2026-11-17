import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import 'identity_verification_providers.dart';

/// The screens of the identity check, in the order they are walked.
enum IdentityFlowStep {
  loading,
  intro,

  /// Briefs before the checker's own flow, as Nu shows them; no photo here.
  frontBrief,
  backBrief,
  selfieBrief,
  pending,
  approved,
  rejected,
}

const _walked = [
  IdentityFlowStep.intro,
  IdentityFlowStep.frontBrief,
  IdentityFlowStep.backBrief,
  IdentityFlowStep.selfieBrief,
];

final class IdentityFlowState {
  const IdentityFlowState({
    this.step = IdentityFlowStep.loading,
    this.busy = false,
    this.failure,
    this.rejection,
    this.canRetry = false,
  });

  final IdentityFlowStep step;

  /// The checker's flow is open.
  final bool busy;

  /// The last action's refusal; any later change clears it.
  final DataFailure? failure;

  /// Why the checker refused, while [step] is rejected.
  final String? rejection;

  /// Whether a refusal may be tried again.
  final bool canRetry;

  /// 0..1 across the intro and briefs; null on the screens around them.
  double? get progress {
    final i = _walked.indexOf(step);
    return i < 0 ? null : (i + 1) / _walked.length;
  }

  IdentityFlowState copyWith({
    IdentityFlowStep? step,
    bool? busy,
    DataFailure? failure,
    String? rejection,
    bool? canRetry,
  }) => IdentityFlowState(
    step: step ?? this.step,
    busy: busy ?? this.busy,
    failure: failure,
    rejection: rejection ?? this.rejection,
    canRetry: canRetry ?? this.canRetry,
  );
}

/// Walks a person through the briefs, then hands off once to the checker.
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
      Ok(:final value) => _showing(value, notStarted: IdentityFlowStep.intro),
      Err(:final failure) => state.copyWith(
        step: IdentityFlowStep.intro,
        failure: failure,
      ),
    };
  }

  /// The gate: true only once approved; loads the status first if needed.
  Future<bool> verified() async {
    if (state.step == IdentityFlowStep.loading) await refresh();
    return state.step == IdentityFlowStep.approved;
  }

  /// Continuar on the intro or a brief; the last brief starts instead.
  void next() {
    final i = _walked.indexOf(state.step);
    if (i >= 0 && i < _walked.length - 1) _goTo(_walked[i + 1]);
  }

  /// Empezar on the selfie brief: the checker's flow, then its answer.
  Future<void> start() async {
    if (state.step != IdentityFlowStep.selfieBrief || state.busy) return;
    state = state.copyWith(busy: true);
    final result = await _port.verify();
    if (!ref.mounted) return;
    state = switch (result) {
      // Not started means the person closed the checker: they stay here.
      Ok(:final value) => _showing(
        value,
        notStarted: IdentityFlowStep.selfieBrief,
      ).copyWith(busy: false),
      Err(:final failure) => state.copyWith(busy: false, failure: failure),
    };
  }

  /// After a refusal that allows it, the briefs come round again.
  void retry() {
    if (state.step != IdentityFlowStep.rejected || !state.canRetry) return;
    _goTo(IdentityFlowStep.frontBrief);
  }

  void back() {
    if (state.busy) return;
    final i = _walked.indexOf(state.step);
    if (i > 0) _goTo(_walked[i - 1]);
  }

  void acknowledgeFailure() => state = state.copyWith();

  IdentityFlowState _showing(
    IdentityCheckStatus status, {
    required IdentityFlowStep notStarted,
  }) => switch (status) {
    IdentityCheckNotStarted() => state.copyWith(step: notStarted),
    IdentityCheckPending() => state.copyWith(step: IdentityFlowStep.pending),
    IdentityCheckApproved() => state.copyWith(step: IdentityFlowStep.approved),
    IdentityCheckRejected(:final reason, :final canRetry) => state.copyWith(
      step: IdentityFlowStep.rejected,
      rejection: reason,
      canRetry: canRetry,
    ),
  };

  void _goTo(IdentityFlowStep step) => state = state.copyWith(step: step);
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
