import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Why each guarded action needs an account, said to a guest.
abstract final class AccountReason {
  static const requests = 'Inicia sesión para responder solicitudes.';
  static const offers = 'Inicia sesión para publicar y editar tus servicios.';
  static const availability = 'Inicia sesión para manejar tu disponibilidad.';
  static const chat = 'Inicia sesión para escribirle a tus clientes.';
  static const projects = 'Inicia sesión para cotizar este proyecto.';
}

/// Runs [action] for an account; a guest gets the account-needed sheet instead.
Future<void> requireAccount(
  BuildContext context,
  WidgetRef ref, {
  required String reason,
  required FutureOr<void> Function() action,
}) async {
  if (ref.read(hasAccountProvider)) return action();
  // Captured first: signing in replaces the shell, and this ref with it.
  final session = ref.read(sessionProvider.notifier);
  await showManoSheet<void>(
    context: context,
    builder: (sheet) => ManoAccountNeededSheet(
      message: reason,
      onClose: () => Navigator.pop(sheet),
      onSignIn: () {
        Navigator.pop(sheet);
        session.leaveGuest();
      },
    ),
  );
}
