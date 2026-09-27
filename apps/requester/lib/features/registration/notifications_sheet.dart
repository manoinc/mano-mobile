import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Step 3: the one permission worth asking for, and why.
///
/// Pops `true` when accepted. Submitting is the caller's job, so the sheet is
/// gone before the flow moves on.
class NotificationsSheet extends ConsumerWidget {
  const NotificationsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(onboardingFlowProvider);
    final wantsPromotions = flow is OnboardingRegistration
        ? flow.draft.wantsPromotions
        : true;
    final busy =
        flow is OnboardingRegistration && flow.status is RegistrationSubmitting;

    return ManoPromptSheet(
      title: 'Activa las notificaciones',
      message:
          'No te pierdas mensajes importantes sobre detalles de tus '
          'servicios y la actividad de tu cuenta.',
      onClose: () => Navigator.of(context).pop(false),
      primaryLabel: 'Sí, notifícame',
      onPrimary: busy ? null : () => Navigator.of(context).pop(true),
      child: ManoToggleRow(
        label: 'Recibir ofertas de mantenimiento, recomendados y más.',
        value: wantsPromotions,
        onChanged: (value) => ref
            .read(onboardingFlowProvider.notifier)
            .setWantsPromotions(value: value),
      ),
    );
  }
}
