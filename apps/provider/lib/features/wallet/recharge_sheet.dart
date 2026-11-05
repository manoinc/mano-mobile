import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'purchase_form.dart';
import 'purchase_status_view.dart';

/// Pick a pack and pay by Nequi or PSE; resolves `true` once the coins landed.
Future<bool?> showRechargeSheet(BuildContext context) =>
    showManoSheet<bool>(context: context, builder: (_) => const _Recharge());

class _Recharge extends ConsumerStatefulWidget {
  const _Recharge();

  @override
  ConsumerState<_Recharge> createState() => _RechargeState();
}

class _RechargeState extends ConsumerState<_Recharge> {
  final _phone = TextEditingController();
  final _legalId = TextEditingController();
  final _email = TextEditingController();
  late final AppLifecycleListener _lifecycle;
  late final bool _askEmail;
  late CoinPurchaseDraft _draft;

  CoinPurchaseController get _controller =>
      ref.read(coinPurchaseProvider.notifier);

  @override
  void initState() {
    super.initState();
    final email = ref.read(accountEmailProvider);
    _askEmail = validateEmail(email) != null;
    _draft = CoinPurchaseDraft(payerEmail: email);
    // Back from Nequi or the bank: look at once instead of waiting for the next tick.
    _lifecycle = AppLifecycleListener(onResume: () => _controller.checkNow());
    final flow = ref.read(coinPurchaseProvider);
    if (flow is PurchaseCredited || flow is PurchaseFailed) {
      Future.microtask(_controller.reset);
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _phone.dispose();
    _legalId.dispose();
    _email.dispose();
    super.dispose();
  }

  void _update(CoinPurchaseDraft Function(CoinPurchaseDraft) change) =>
      setState(() => _draft = change(_draft));

  void _pay(CoinPack pack) => _controller.buy(_draft.copyWith(packId: pack.id));

  Future<void> _openBank(String url) async {
    final opened = await ref.read(externalLinkOpenerProvider)(Uri.parse(url));
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos abrir la página del banco.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(coinPurchaseProvider);
    final packs = ref.watch(coinPacksProvider).value ?? const <CoinPack>[];
    if (_draft.packId.isEmpty && packs.isNotEmpty) {
      // Preselect the middle pack, the one most people take.
      _draft = _draft.copyWith(packId: packs[packs.length > 1 ? 1 : 0].id);
    }
    final form = flow is PurchaseIdle || flow is PurchaseSubmitting;

    return SafeArea(
      key: const Key('recharge-sheet'),
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          ManoSpacing.lg,
          ManoSpacing.lg,
          ManoSpacing.lg,
          ManoSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: AnimatedSwitcher(
          duration: ManoMotion.normal,
          child: form
              ? PurchaseForm(
                  key: const ValueKey('form'),
                  draft: _draft,
                  phone: _phone,
                  legalId: _legalId,
                  email: _email,
                  askEmail: _askEmail,
                  busy: flow is PurchaseSubmitting,
                  onChanged: _update,
                  onPay: _pay,
                )
              : PurchaseStatusView(
                  key: const ValueKey('status'),
                  flow: flow,
                  onOpenBank: _openBank,
                  onCheckAgain: _controller.checkNow,
                  onRetry: _controller.reset,
                  onDone: () => Navigator.of(context).pop(true),
                  onClose: () => Navigator.of(context).pop(),
                ),
        ),
      ),
    );
  }
}
