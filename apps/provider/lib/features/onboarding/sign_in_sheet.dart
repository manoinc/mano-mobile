import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// "Ya tengo cuenta": email and password in a sheet, failures shown inside it.
Future<void> showSignInSheet(BuildContext context, WidgetRef ref) {
  // Captured first: a successful sign-in replaces the caller, and its ref with it.
  final session = ref.read(sessionProvider.notifier);
  return showManoSheet<void>(
    context: context,
    builder: (sheet) => ManoCredentialsSheet(
      title: 'Inicia sesión',
      message: 'Con el correo de tu cuenta profesional.',
      submitLabel: 'Entrar',
      onSubmit: (email, password) async {
        final failure = await session.signIn(
          Credentials(email: email, password: password),
        );
        if (failure != null) {
          session.acknowledgeFailure();
          return authFailureCopy(failure);
        }
        if (sheet.mounted) Navigator.of(sheet).pop();
        return null;
      },
    ),
  );
}
