import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../account/account_gate.dart';
import '../identity/identity_row.dart';
import '../payouts/payout_labels.dart';

/// Perfil's account rows: identity, where payouts go, and help (PQRS).
class AccountRows extends ConsumerWidget {
  const AccountRows({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(payoutAccountProvider).value;
    final divider = Divider(
      height: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
    return Column(
      children: [
        const IdentityRow(),
        divider,
        ManoOptionRow(
          icon: Icons.account_balance_outlined,
          label: 'Cuenta para pagos',
          detail: account == null
              ? 'Agrega dónde recibir lo que ganas'
              : destinationLine(
                  account.destination,
                  ref.watch(payoutBanksProvider).value ?? const [],
                ),
          onPressed: () => requireAccount(
            context,
            ref,
            reason: AccountReason.payouts,
            action: () => context.push('/profile/payout'),
          ),
        ),
        divider,
        ManoOptionRow(
          icon: Icons.support_agent_outlined,
          label: 'Ayuda y PQRS',
          detail: 'Peticiones, quejas, reclamos y sugerencias',
          onPressed: () => context.push('/profile/support'),
        ),
      ],
    );
  }
}
