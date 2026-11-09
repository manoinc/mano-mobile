import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';

/// One box per digit over a single hidden field, so SMS autofill and paste just work.
class ManoOtpField extends StatefulWidget {
  const ManoOtpField({
    required this.value,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
    super.key,
  });

  /// The digits so far; the field follows it when the screen resets the code.
  final String value;
  final int length;
  final ValueChanged<String>? onChanged;

  /// Fires once all [length] digits are in.
  final ValueChanged<String>? onCompleted;
  final String? errorText;
  final bool enabled;
  final bool autofocus;

  @override
  State<ManoOtpField> createState() => _ManoOtpFieldState();
}

class _ManoOtpFieldState extends State<ManoOtpField> {
  late final _controller = TextEditingController(text: widget.value);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(ManoOtpField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed(String code) {
    setState(() {});
    widget.onChanged?.call(code);
    if (code.length == widget.length) widget.onCompleted?.call(code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final code = _controller.text;
    final error = widget.errorText;

    Color borderFor(int i) {
      if (error != null) return scheme.error;
      final active =
          _focus.hasFocus && i == code.length.clamp(0, widget.length - 1);
      return active ? ManoColors.flame : scheme.outlineVariant;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            // Kept in the tree, invisible, so the keyboard, autofill and paste go to it.
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  enabled: widget.enabled,
                  onChanged: _changed,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  showCursor: false,
                  enableInteractiveSelection: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.enabled ? _focus.requestFocus : null,
              child: Row(
                children: [
                  for (var i = 0; i < widget.length; i++) ...[
                    if (i > 0) const SizedBox(width: ManoSpacing.sm),
                    Expanded(
                      child: AnimatedContainer(
                        duration: ManoMotion.quick,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(ManoRadius.card),
                          border: Border.all(color: borderFor(i), width: 1.5),
                        ),
                        child: Text(
                          i < code.length ? code[i] : '',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: ManoSpacing.sm),
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}
