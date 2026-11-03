import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../session_providers.dart';
import 'review_copy.dart';
import 'review_providers.dart';

/// The rating sheet's state for one job.
final class RatingFlowState {
  const RatingFlowState({
    this.draft = const ReviewDraft(),
    this.busy = false,
    this.error,
    this.ratedStars,
  });

  final ReviewDraft draft;
  final bool busy;

  /// Spanish copy for the last refusal, or null.
  final String? error;

  /// The stars the service stored; set once the rating went through.
  final int? ratedStars;

  bool get isDone => ratedStars != null;

  bool get canSubmit => draft.stars > 0 && !busy && !isDone;

  RatingFlowState copyWith({
    ReviewDraft? draft,
    bool? busy,
    String? Function()? error,
    int? ratedStars,
  }) => RatingFlowState(
    draft: draft ?? this.draft,
    busy: busy ?? this.busy,
    error: error == null ? this.error : error(),
    ratedStars: ratedStars ?? this.ratedStars,
  );
}

/// Rating the other side of a finished job; the app's role picks the side.
final ratingFlowProvider = NotifierProvider.autoDispose
    .family<RatingFlow, RatingFlowState, String>(RatingFlow.new);

final class RatingFlow extends Notifier<RatingFlowState> {
  RatingFlow(this.jobId);

  final String jobId;

  @override
  RatingFlowState build() =>
      RatingFlowState(ratedStars: ref.read(ratedStarsProvider(jobId)));

  void setStars(int stars) => _edit(state.draft.copyWith(stars: stars));

  void setComment(String comment) =>
      _edit(state.draft.copyWith(comment: comment));

  /// Sends the draft; true once the rating is stored.
  Future<bool> submit() async {
    if (!state.canSubmit) return false;
    final draft = state.draft.copyWith(comment: state.draft.comment.trim());
    if (draft.problems case final problems when problems.isNotEmpty) {
      state = state.copyWith(error: () => reviewProblemCopy(problems.first));
      return false;
    }
    state = state.copyWith(busy: true, error: () => null);
    final actions = ref.read(reviewActionsProvider.notifier);
    final result = ref.read(manoConfigProvider).appRole == ManoRole.provider
        ? await actions.reviewClient(jobId, draft)
        : await actions.reviewProvider(jobId, draft);
    if (!ref.mounted) return result.isOk;
    state = switch (result) {
      Ok(:final value) => state.copyWith(busy: false, ratedStars: value.stars),
      Err(:final failure) => state.copyWith(
        busy: false,
        error: () => reviewFailureCopy(failure),
      ),
    };
    return result.isOk;
  }

  void _edit(ReviewDraft draft) =>
      state = state.copyWith(draft: draft, error: () => null);
}
