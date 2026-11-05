import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../wallet/recharge_sheet.dart';
import '../wallet/wallet_labels.dart';
import 'insufficient_coins_sheet.dart';

/// Buy the selected quote's lead with coins; unlocks the requester's contact.
Future<void> showLeadPurchaseSheet(BuildContext context, Quote quote) =>
    showManoSheet<void>(
      context: context,
      builder: (_) => _LeadPurchase(quote: quote),
    );

class _LeadPurchase extends ConsumerStatefulWidget {
  const _LeadPurchase({required this.quote});

  final Quote quote;

  @override
  ConsumerState<_LeadPurchase> createState() => _LeadPurchaseState();
}

class _LeadPurchaseState extends ConsumerState<_LeadPurchase> {
  bool _busy = false;

  Future<void> _buy(int cost) async {
    setState(() => _busy = true);
    final result = await ref
        .read(leadActionsProvider.notifier)
        .purchaseLead(widget.quote.id);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok():
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Contacto desbloqueado')));
      case Err(failure: InsufficientCoins()):
        final balance = (await ref.read(walletProvider.future)).balance;
        if (!mounted) return;
        final recharge = await showInsufficientCoinsSheet(
          context,
          needed: cost,
          available: balance,
        );
        if (recharge == true && mounted) await showRechargeSheet(context);
      case Err(:final failure):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final balance = ref.watch(walletProvider).value?.balance;
    final cost = ref
        .watch(leadPricesProvider)
        .value
        ?.costFor(widget.quote.projectCategory);
    return SafeArea(
      key: const Key('lead-purchase-sheet'),
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(ManoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Compra el contacto', style: textTheme.headlineSmall),
            const SizedBox(height: ManoSpacing.sm),
            Text(
              'El cliente eligió tu cotización para «${widget.quote.projectTitle}». '
              'Con su contacto acuerdan el trabajo directamente.',
              style: textTheme.bodyLarge?.copyWith(color: ManoColors.muted),
            ),
            const SizedBox(height: ManoSpacing.md),
            if (cost != null)
              ManoDetailRow(label: 'Costo', value: coinsLabel(cost)),
            if (balance != null)
              ManoDetailRow(label: 'Tu saldo', value: coinsLabel(balance)),
            const SizedBox(height: ManoSpacing.lg),
            ManoPrimaryButton(
              label: cost == null ? 'Comprar' : 'Comprar · ${coinsLabel(cost)}',
              busy: _busy,
              onPressed: cost == null ? null : () => _buy(cost),
            ),
          ],
        ),
      ),
    );
  }
}
