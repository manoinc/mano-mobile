import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'how_it_works_sheet.dart';
import 'recharge_sheet.dart';
import 'wallet_labels.dart';

/// Billetera: the coin balance, recharge, and what each coin was spent on.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final history = ref.watch(walletHistoryProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            ManoSpacing.md,
            ManoSpacing.md,
            ManoSpacing.md,
            ManoSpacing.lg,
          ),
          children: [
            Text('Billetera', style: Theme.of(context).textTheme.headlineSmall),
            ManoBalanceHero(
              amount: wallet.hasValue ? '${wallet.requireValue.balance}' : '–',
              unit: 'Mano coins',
              actions: Row(
                children: [
                  Expanded(
                    child: ManoPrimaryButton(
                      label: 'Recargar',
                      onPressed: () => showRechargeSheet(context),
                    ),
                  ),
                  const SizedBox(width: ManoSpacing.sm),
                  Expanded(
                    child: ManoOutlineButton(
                      label: 'Cómo funciona',
                      onPressed: () => showHowItWorksSheet(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ManoSpacing.md),
            Text('Actividad', style: Theme.of(context).textTheme.titleLarge),
            ..._activity(context, history),
          ],
        ),
      ),
    );
  }

  List<Widget> _activity(
    BuildContext context,
    AsyncValue<List<CoinTransaction>> history,
  ) {
    if (!history.hasValue) {
      return const [Center(child: CircularProgressIndicator())];
    }
    final now = DateTime.now();
    final groups = <String, List<CoinTransaction>>{};
    for (final t in history.requireValue) {
      groups.putIfAbsent(activityGroup(t.at, now), () => []).add(t);
    }
    return [
      for (final MapEntry(:key, :value) in groups.entries) ...[
        Padding(
          padding: const EdgeInsets.only(
            top: ManoSpacing.md,
            bottom: ManoSpacing.xs,
          ),
          child: Text(
            key,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: ManoColors.faint),
          ),
        ),
        for (final t in value)
          ManoActivityTile(
            icon: transactionIcon(t.kind),
            title: t.label,
            subtitle: ManoFormat.dayMonth(t.at),
            amountLabel: signedCoins(t.amount),
            positive: t.isCredit,
          ),
      ],
    ];
  }
}
