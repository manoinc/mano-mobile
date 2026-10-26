import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// True when an account is signed in; otherwise tells the guest why one is needed.
bool requireAccount(BuildContext context, WidgetRef ref, String message) {
  if (ref.read(hasAccountProvider)) return true;
  showManoSheet<void>(
    context: context,
    builder: (sheet) => ManoPromptSheet(
      title: 'Necesitas una cuenta',
      message: message,
      primaryLabel: 'Iniciar sesión',
      onClose: () => Navigator.pop(sheet),
      onPrimary: () {
        Navigator.pop(sheet);
        ref.read(sessionProvider.notifier).leaveGuest();
      },
    ),
  );
  return false;
}
