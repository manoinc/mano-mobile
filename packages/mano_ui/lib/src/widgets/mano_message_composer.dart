import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';
import 'mano_photo_picker_grid.dart';
import 'picked_photo_tile.dart';

/// A text field with a send button, an optional attach button and pending photos.
class ManoMessageComposer extends StatefulWidget {
  const ManoMessageComposer({
    required this.hintText,
    required this.onSend,
    this.onAttach,
    this.attachments = const [],
    this.onRemoveAttachment,
    this.onRetryAttachment,
    this.canSend = true,
    super.key,
  });

  final String hintText;

  /// Gets the trimmed draft (empty for photos only); true clears the field.
  final FutureOr<bool> Function(String text) onSend;

  /// Shows the "+" button; null hides it.
  final VoidCallback? onAttach;

  /// Photos waiting to go with the next message.
  final List<ManoPickedPhoto> attachments;
  final ValueChanged<String>? onRemoveAttachment;
  final ValueChanged<String>? onRetryAttachment;

  /// False while something, e.g. a photo upload, must finish first.
  final bool canSend;

  @override
  State<ManoMessageComposer> createState() => _ManoMessageComposerState();
}

class _ManoMessageComposerState extends State<ManoMessageComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!widget.canSend) return;
    final text = _controller.text.trim();
    if (text.isEmpty && widget.attachments.isEmpty) return;
    if (await widget.onSend(text) && mounted) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ManoSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSize(
            duration: ManoMotion.normal,
            curve: ManoMotion.entrance,
            alignment: Alignment.bottomCenter,
            child: widget.attachments.isEmpty
                ? const SizedBox(width: double.infinity)
                : _AttachmentStrip(
                    photos: widget.attachments,
                    onRemove: widget.onRemoveAttachment,
                    onRetry: widget.onRetryAttachment,
                  ),
          ),
          Row(
            children: [
              if (widget.onAttach != null) ...[
                IconButton(
                  key: const Key('mano-composer-attach'),
                  tooltip: 'Agregar foto',
                  onPressed: widget.onAttach,
                  icon: const Icon(Icons.add_rounded),
                ),
                const SizedBox(width: ManoSpacing.xs),
              ],
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    filled: true,
                    fillColor: ManoColors.sand,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: ManoSpacing.md,
                      vertical: ManoSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ManoRadius.pill),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: ManoSpacing.sm),
              IconButton.filled(
                key: const Key('mano-composer-send'),
                onPressed: widget.canSend ? _send : null,
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachmentStrip extends StatelessWidget {
  const _AttachmentStrip({
    required this.photos,
    required this.onRemove,
    required this.onRetry,
  });

  static const _side = 72.0;

  final List<ManoPickedPhoto> photos;
  final ValueChanged<String>? onRemove;
  final ValueChanged<String>? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    key: const Key('mano-composer-attachments'),
    padding: const EdgeInsets.only(bottom: ManoSpacing.sm),
    child: SizedBox(
      height: _side,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: ManoSpacing.sm),
        itemBuilder: (context, i) => SizedBox.square(
          key: ValueKey(photos[i].id),
          dimension: _side,
          child: PickedPhotoTile(
            photo: photos[i],
            position: i + 1,
            onRemove: onRemove,
            onRetry: onRetry,
          ),
        ),
      ),
    ),
  );
}
