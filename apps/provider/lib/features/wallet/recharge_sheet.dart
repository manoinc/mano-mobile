import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'wallet_labels.dart';

/// Pick a coin pack and pay it with Nequi; resolves `true` once the purchase started.
Future<bool?> showRechargeSheet(BuildContext context) =>
    showManoSheet<bool>(context: context, builder: (_) => const _Recharge());

class _Recharge extends ConsumerStatefulWidget {
  const _Recharge();

  @override
  ConsumerState<_Recharge> createState() => _RechargeState();
}

class _RechargeState extends ConsumerState<_Recharge> {
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String? _selectedId;
  bool _acceptedTerms = false;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _ready =>
      _acceptedTerms &&
      RegExp(r'^3\d{9}$').hasMatch(_phone.text.trim()) &&
      _email.text.contains('@');

  Future<void> _buy(CoinPack pack) async {
    setState(() => _busy = true);
    final result = await ref
        .read(walletActionsProvider.notifier)
        .buyPack(
          pack.id,
          NequiPayment(
            phone: _phone.text.trim(),
            payerEmail: _email.text.trim(),
            acceptedTerms: _acceptedTerms,
          ),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Ok(:final value):
        Navigator.of(context).pop(true);
        messenger.showSnackBar(SnackBar(content: Text(purchaseNotice(value))));
      case Err(:final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final packs = ref.watch(coinPacksProvider).value ?? const <CoinPack>[];
    final terms = ref.watch(checkoutTermsProvider).value ?? const [];
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
            ManoTextField(
              key: const Key('recharge-phone'),
              label: 'Celular Nequi',
              controller: _phone,
              keyboardType: TextInputType.phone,
              helperText: 'Te llegará una notificación para aprobar el pago',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: ManoSpacing.sm),
            ManoTextField(
              key: const Key('recharge-email'),
              label: 'Correo para el comprobante',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: ManoSpacing.sm),
            ManoToggleRow(
              key: const Key('recharge-terms'),
              label: terms.isEmpty
                  ? 'Acepto los términos del pago'
                  : 'Acepto ${terms.map((t) => t.label).join(' y ')}',
              value: _acceptedTerms,
              onChanged: (value) => setState(() => _acceptedTerms = value),
            ),
            const SizedBox(height: ManoSpacing.md),
            ManoPrimaryButton(
              label: selected == null
                  ? 'Pagar con Nequi'
                  : 'Pagar con Nequi · ${ManoFormat.cop(selected.priceCop)}',
              busy: _busy,
              onPressed: selected == null || !_ready
                  ? null
                  : () => _buy(selected),
            ),
          ],
        ),
      ),
    );
  }
}
