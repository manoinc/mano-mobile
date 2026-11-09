import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../account/account_gate.dart';

/// Perfil's identity row: where the check stands, and the way into it.
class IdentityRow extends ConsumerWidget {
  const IdentityRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(identityFlowProvider.select((s) => s.step));
    final (label, detail) = switch (step) {
      IdentityFlowStep.approved => (
        'Identidad verificada',
        'Tus clientes ven la insignia en tu perfil',
      ),
      IdentityFlowStep.pending => (
        'Verificación en revisión',
        'Te avisaremos cuando terminemos',
      ),
      IdentityFlowStep.rejected => (
        'Verifica tu identidad de nuevo',
        'Hubo un problema con tus fotos',
      ),
      _ => ('Verifica tu identidad', 'Tu cédula y una selfie, en un minuto'),
    };
    return ManoOptionRow(
      icon: step == IdentityFlowStep.approved
          ? Icons.verified
          : Icons.badge_outlined,
      label: label,
      detail: detail,
      onPressed: () => requireAccount(
        context,
        ref,
        reason: AccountReason.identity,
        action: () => context.push('/profile/identity'),
      ),
    );
  }
}
