import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A text field with a send button; owns only its draft text.
class ManoMessageComposer extends StatefulWidget {
  const ManoMessageComposer({
    required this.hintText,
    required this.onSend,
    super.key,
  });

  final String hintText;
  final ValueChanged<String> onSend;

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

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ManoSpacing.sm),
      child: Row(
        children: [
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
            onPressed: _send,
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
    );
  }
}
