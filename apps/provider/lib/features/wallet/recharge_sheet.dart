import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'wallet_labels.dart';

/// Pick a coin pack and buy it (mocked); resolves `true` once coins were added.
Future<bool?> showRechargeSheet(BuildContext context) =>
    showManoSheet<bool>(context: context, builder: (_) => const _Recharge());

class _Recharge extends ConsumerStatefulWidget {
  const _Recharge();

  @override
  ConsumerState<_Recharge> createState() => _RechargeState();
}

class _RechargeState extends ConsumerState<_Recharge> {
  String? _selectedId;
  bool _busy = false;

  Future<void> _buy(CoinPack pack) async {
    setState(() => _busy = true);
    final result = await ref
        .read(walletActionsProvider.notifier)
        .buyPack(pack.id);
    if (!mounted) return;
    if (result.isOk) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(result.failureOrNull!.message)));
  }

  @override
  Widget build(BuildContext context) {
    final packs = ref.watch(coinPacksProvider).value ?? const <CoinPack>[];
    final selected = packs.isEmpty
        ? null
        : packs.firstWhere(
            (p) => p.id == _selectedId,
            orElse: () => packs[packs.length > 1 ? 1 : 0],
          );

    return SafeArea(
      key: const Key('recharge-sheet'),
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ManoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recargar coins',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: ManoSpacing.md),
            for (final pack in packs) ...[
              ManoPackOption(
                coinsLabel: coinsLabel(pack.coins),
                priceLabel: ManoFormat.cop(pack.priceCop),
                bonusLabel: pack.bonus > 0 ? '+${pack.bonus} gratis' : null,
                selected: pack.id == selected?.id,
                onTap: () => setState(() => _selectedId = pack.id),
              ),
              const SizedBox(height: ManoSpacing.sm),
            ],
            const SizedBox(height: ManoSpacing.sm),
            ManoPrimaryButton(
              label: selected == null
                  ? 'Comprar'
                  : 'Comprar · ${ManoFormat.cop(selected.priceCop)}',
              busy: _busy,
              onPressed: selected == null ? null : () => _buy(selected),
            ),
          ],
        ),
      ),
    );
  }
}
