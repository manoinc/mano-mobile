import 'package:flutter/material.dart';

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
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
