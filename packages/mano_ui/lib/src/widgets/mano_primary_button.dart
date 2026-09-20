import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';

/// The main action on a screen.
///
/// Takes a label, a callback and a flag — nothing else. It has no idea what
/// signing in means, cannot reach application state, and could not render a
/// `Session` if it wanted to, because `mano_ui` does not depend on the domain.
///
/// That is what makes it reusable in both apps and testable by handing it
/// three values.
class ManoPrimaryButton extends StatelessWidget {
  const ManoPrimaryButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    super.key,
  });

  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;

  /// Shows a spinner and ignores taps. Separate from a null [onPressed] so a
  /// screen can distinguish "working" from "not available".
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _PressScale(
      enabled: !busy && onPressed != null,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        child: busy
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  // On a flame fill the default indicator is nearly invisible.
                  color: scheme.onPrimary,
                ),
              )
            : Text(label),
      ),
    );
  }
}

/// Takes a press down by a hair.
///
/// The stylesheet lifts this button on hover; a phone has no hover, so the
/// press gets the equivalent acknowledgement instead. Small enough to feel
/// rather than watch.
class _PressScale extends StatefulWidget {
  const _PressScale({required this.child, required this.enabled});

  final Widget child;
  final bool enabled;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (widget.enabled && _down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: ManoMotion.quick,
        curve: ManoMotion.entrance,
        child: widget.child,
      ),
    );
  }
}
