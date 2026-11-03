import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Opens the sheet to rate [job]'s provider.
Future<void> showJobRatingSheet(BuildContext context, Job job) =>
    showManoSheet<void>(
      context: context,
      builder: (_) => _JobRatingSheet(job: job),
    );

class _JobRatingSheet extends ConsumerWidget {
  const _JobRatingSheet({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(ratingFlowProvider(job.id));
    final actions = ref.read(ratingFlowProvider(job.id).notifier);
    void close() => Navigator.of(context).pop();
    return ManoRatingSheet(
      title: '¿Cómo te fue con ${job.providerName}?',
      subtitle: 'Tu calificación ayuda a otros a elegir bien.',
      stars: flow.draft.stars,
      onStarsChanged: actions.setStars,
      onCommentChanged: actions.setComment,
      onSubmit: flow.canSubmit ? actions.submit : null,
      onClose: close,
      busy: flow.busy,
      error: flow.error,
      done: flow.isDone,
      doneTitle: '¡Gracias por calificar!',
      doneMessage: 'Tu opinión ayuda a que Mano siga siendo confiable.',
      onDone: close,
    );
  }
}
