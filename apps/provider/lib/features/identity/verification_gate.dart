import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../account/account_gate.dart';

/// Runs [action] for a verified pro; a guest signs in first, anyone else verifies.
Future<void> requireVerified(
  BuildContext context,
  WidgetRef ref, {
  required String reason,
  required FutureOr<void> Function() action,
}) => requireAccount(
  context,
  ref,
  reason: reason,
  action: () async {
    final flow = ref.read(identityFlowProvider.notifier);
    if (await flow.verified()) return action();
    if (!context.mounted) return;
    await showManoSheet<void>(
      context: context,
      builder: (sheet) => ManoPromptSheet(
        title: 'Verifica tu identidad para continuar',
        message:
            'Antes de escribirle o comprometerte con un cliente, confirma '
            'quién eres con tu cédula y una selfie.',
        primaryLabel: 'Verificar ahora',
        onPrimary: () {
          Navigator.pop(sheet);
          context.push('/profile/identity');
        },
        secondaryLabel: 'Ahora no',
        onSecondary: () => Navigator.pop(sheet),
        onClose: () => Navigator.pop(sheet),
      ),
    );
  },
);
