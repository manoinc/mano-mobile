import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'chat_photo_block.dart';
import 'mano_photo_picker_grid.dart';
import 'mano_receipt_mark.dart';

/// One chat message; [mine] puts it on the right in ink.
///
/// Bubbles in a run from one sender tighten the corners they share, so the run
/// reads as one block: [isFirstInGroup] and [isLastInGroup] say where this one
/// sits. The time and receipt belong to the run, so only the last bubble gets a
/// [timeLabel]. [photos] sit above the text; an empty [text] draws photos only.
class ManoChatBubble extends StatelessWidget {
  const ManoChatBubble({
    required this.text,
    required this.mine,
    this.timeLabel,
    this.receipt,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.photos = const [],
    this.photoStatus = ManoPhotoStatus.done,
    this.onPhotoTap,
    this.photoHeroTags,
    super.key,
  });

  final String text;
  final bool mine;

  /// `null` hides the time, for a bubble that is not last in its group.
  final String? timeLabel;

  /// Shown beside the time on my messages only.
  final ManoReceipt? receipt;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  final List<ImageProvider> photos;

  /// Uploading or failed, for my message that is still on its way.
  final ManoPhotoStatus photoStatus;

  /// Gets the index of the tapped photo.
  final ValueChanged<int>? onPhotoTap;

  /// One per photo, for a [Hero] into the full-screen viewer.
  final List<Object>? photoHeroTags;

  BorderRadius get _radius {
    const round = Radius.circular(ManoRadius.lg);
    const tight = Radius.circular(ManoRadius.sm);
    final top = isFirstInGroup ? round : tight;
    final bottom = isLastInGroup ? round : tight;
    return mine
        ? BorderRadius.only(
            topLeft: round,
            bottomLeft: round,
            topRight: top,
            bottomRight: bottom,
          )
        : BorderRadius.only(
            topRight: round,
            bottomRight: round,
            topLeft: top,
            bottomLeft: bottom,
          );
  }

  // Time and receipt share the last text line when they fit, else take their own.
  Widget _withMeta(
    BuildContext context, {
    required double maxWidth,
    required TextStyle? bodyStyle,
    required TextStyle? timeStyle,
    required String time,
    required ManoReceiptMark? mark,
    required Widget meta,
  }) {
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final body = TextPainter(
      text: TextSpan(text: text, style: bodyStyle),
      textDirection: direction,
      textScaler: scaler,
    )..layout(maxWidth: maxWidth);
    final stamp = TextPainter(
      text: TextSpan(text: time, style: timeStyle),
      textDirection: direction,
      textScaler: scaler,
    )..layout();
    final metaWidth =
        stamp.width + (mark == null ? 0 : ManoSpacing.xs + mark.width);
    final metaHeight = mark == null
        ? stamp.height
        : (stamp.height > mark.size ? stamp.height : mark.size);
    final lines = body.computeLineMetrics();
    final lastLine = lines.isEmpty ? body.width : lines.last.width;
    final inline = lastLine + ManoSpacing.sm + metaWidth <= maxWidth;
    final width = inline
        ? (body.width > lastLine + ManoSpacing.sm + metaWidth
              ? body.width
              : lastLine + ManoSpacing.sm + metaWidth)
        : (body.width > metaWidth ? body.width : metaWidth);
    final height = inline ? body.height : body.height + metaHeight;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            child: Text(text, style: bodyStyle),
          ),
          Positioned(right: 0, bottom: 0, child: meta),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.75;
    final Widget child;
    if (photos.isEmpty) {
      child = _textBubble(context);
    } else {
      final time = timeLabel;
      child = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          ChatPhotoBlock(
            photos: photos,
            width: maxWidth < _photoWidth ? maxWidth : _photoWidth,
            status: photoStatus,
            onTap: onPhotoTap,
            heroTags: photoHeroTags,
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: ManoSpacing.xs),
            _textBubble(context),
          ] else if (time != null)
            Padding(
              padding: const EdgeInsets.only(top: ManoSpacing.xs),
              child: _meta(context, time, context.palette.faint),
            ),
        ],
      );
    }
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  static const _photoWidth = 260.0;

  ManoReceiptMark? _mark(Color color) => mine && receipt != null
      ? ManoReceiptMark(receipt: receipt!, color: color)
      : null;

  Widget _meta(BuildContext context, String time, Color color) {
    final mark = _mark(color);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          key: const Key('chat-bubble-time'),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
        if (mark != null) ...[const SizedBox(width: ManoSpacing.xs), mark],
      ],
    );
  }

  Widget _textBubble(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foreground = mine ? context.palette.paper : context.palette.ink;
    final quiet = mine ? context.palette.stone : context.palette.faint;
    final bodyStyle = textTheme.bodyMedium?.copyWith(color: foreground);
    final timeStyle = textTheme.labelSmall?.copyWith(color: quiet);
    final time = timeLabel;
    final mark = _mark(quiet);

    Widget content = Text(text, style: bodyStyle);
    if (time != null) {
      final meta = _meta(context, time, quiet);
      content = LayoutBuilder(
        builder: (context, constraints) => _withMeta(
          context,
          maxWidth: constraints.maxWidth,
          bodyStyle: bodyStyle,
          timeStyle: timeStyle,
          time: time,
          mark: mark,
          meta: meta,
        ),
      );
    }
    return DecoratedBox(
      key: const Key('chat-bubble-body'),
      decoration: BoxDecoration(
        color: mine ? context.palette.ink : context.palette.sand,
        borderRadius: _radius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ManoSpacing.sm + ManoSpacing.xs,
          vertical: ManoSpacing.sm,
        ),
        child: content,
      ),
    );
  }
}
