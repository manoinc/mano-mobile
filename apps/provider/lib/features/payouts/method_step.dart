import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Step 1, Wise-style: one row per way to get paid; a tap moves on.
class MethodStep extends StatelessWidget {
  const MethodStep({required this.onPick, required this.onBack, super.key});

  final ValueChanged<PayoutMethod> onPick;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            ManoSpacing.sm,
            0,
            ManoSpacing.lg,
            ManoSpacing.lg,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                iconSize: 20,
                tooltip: 'Atrás',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: ManoSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '¿Dónde quieres recibir tus pagos?',
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: ManoSpacing.sm),
                  Text(
                    'Solo en una cuenta a tu nombre. Puedes cambiarla cuando quieras.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: ManoColors.muted,
                    ),
                  ),
                  const SizedBox(height: ManoSpacing.xl),
                  ManoOptionRow(
                    icon: Icons.phone_iphone,
                    label: 'Nequi',
                    detail: 'Con el celular de tu cuenta Nequi',
                    onPressed: () => onPick(PayoutMethod.nequi),
                  ),
                  Divider(height: 1, color: theme.colorScheme.outlineVariant),
                  ManoOptionRow(
                    icon: Icons.account_balance_outlined,
                    label: 'Cuenta bancaria',
                    detail: 'Ahorros o corriente, en tu banco',
                    onPressed: () => onPick(PayoutMethod.bank),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
