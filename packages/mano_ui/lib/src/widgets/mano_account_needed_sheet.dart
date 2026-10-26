import 'package:flutter/material.dart';

import 'mano_prompt_sheet.dart';

/// Tells a guest that this action needs an account, and offers the way in.
class ManoAccountNeededSheet extends StatelessWidget {
  const ManoAccountNeededSheet({
    required this.message,
    required this.onSignIn,
    required this.onClose,
    this.title = 'Necesitas una cuenta',
    this.signInLabel = 'Iniciar sesión',
    super.key,
  });

  /// What the account unlocks here, in a sentence.
  final String message;
  final VoidCallback onSignIn;
  final VoidCallback onClose;
  final String title;
  final String signInLabel;

  @override
  Widget build(BuildContext context) => ManoPromptSheet(
    title: title,
    message: message,
    primaryLabel: signInLabel,
    onPrimary: onSignIn,
    onClose: onClose,
  );
}
