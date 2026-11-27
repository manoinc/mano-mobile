import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';
import 'mano_notice.dart';
import 'mano_primary_button.dart';
import 'mano_star_input.dart';
import 'mano_text_field.dart';

/// Rates the other side of a finished job: stars, an optional comment, send, thanks.
class ManoRatingSheet extends StatefulWidget {
  const ManoRatingSheet({
    required this.title,
    required this.subtitle,
    required this.stars,
    required this.onStarsChanged,
    required this.onCommentChanged,
    required this.onSubmit,
    required this.onClose,
    required this.doneTitle,
    required this.doneMessage,
    required this.onDone,
    this.busy = false,
    this.error,
    this.done = false,
    this.submitLabel = 'Enviar',
    this.commentLabel = 'Comentario (opcional)',
    this.doneLabel = 'Listo',
    super.key,
  });

  final String title;
  final String subtitle;

  /// Zero until a star is chosen; the comment appears after.
  final int stars;
  final ValueChanged<int> onStarsChanged;
  final ValueChanged<String> onCommentChanged;

  /// Null disables send.
  final VoidCallback? onSubmit;
  final VoidCallback onClose;
  final bool busy;

  /// Why the last send was refused.
  final String? error;

  /// Swaps the form for the thank-you.
  final bool done;
  final String doneTitle;
  final String doneMessage;
  final VoidCallback onDone;
  final String submitLabel;
  final String commentLabel;
  final String doneLabel;

  @override
  State<ManoRatingSheet> createState() => _ManoRatingSheetState();
}

class _ManoRatingSheetState extends State<ManoRatingSheet> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ManoSpacing.lg,
            ManoSpacing.sm,
            ManoSpacing.lg,
            ManoSpacing.lg,
          ),
          child: AnimatedSwitcher(
            duration: ManoMotion.normal,
            switchInCurve: ManoMotion.entrance,
            child: widget.done ? _thanks(context) : _form(context),
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: widget.busy ? null : widget.onClose,
            icon: const Icon(Icons.close),
            iconSize: 22,
            tooltip: 'Cerrar',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: ManoSpacing.sm),
                Text(
                  widget.subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.palette.muted,
                  ),
                ),
                const SizedBox(height: ManoSpacing.lg),
                ManoStarInput(
                  value: widget.stars,
                  onChanged: widget.busy ? (_) {} : widget.onStarsChanged,
                ),
                AnimatedSize(
                  duration: ManoMotion.normal,
                  curve: ManoMotion.entrance,
                  alignment: Alignment.topCenter,
                  child: widget.stars == 0
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: ManoSpacing.lg),
                          child: ManoTextField(
                            label: widget.commentLabel,
                            controller: _comment,
                            onChanged: widget.onCommentChanged,
                            enabled: !widget.busy,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 2,
                            maxLines: 5,
                          ),
                        ),
                ),
                if (widget.error case final error?) ...[
                  const SizedBox(height: ManoSpacing.md),
                  ManoNotice(message: error, tone: ManoNoticeTone.error),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: ManoSpacing.lg),
        ManoPrimaryButton(
          label: widget.submitLabel,
          busy: widget.busy,
          onPressed: widget.onSubmit,
        ),
      ],
    );
  }

  Widget _thanks(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('thanks'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: ManoSpacing.xl),
        Icon(Icons.check_circle_rounded, size: 56, color: context.palette.clay),
        const SizedBox(height: ManoSpacing.md),
        Text(
          widget.doneTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: ManoSpacing.sm),
        Text(
          widget.doneMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.palette.muted,
          ),
        ),
        const SizedBox(height: ManoSpacing.xl),
        ManoPrimaryButton(label: widget.doneLabel, onPressed: widget.onDone),
      ],
    );
  }
}
