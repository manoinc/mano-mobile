import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'bank_step.dart';
import 'destination_step.dart';
import 'holder_step.dart';
import 'method_step.dart';
import 'payout_summary.dart';

/// HU-T6: the saved payout account, or one question per screen to add one.
class PayoutScreen extends ConsumerStatefulWidget {
  const PayoutScreen({super.key});

  @override
  ConsumerState<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends ConsumerState<PayoutScreen> {
  final _phone = TextEditingController();
  final _accountNumber = TextEditingController();
  final _holderName = TextEditingController();
  final _holderEmail = TextEditingController();
  final _legalId = TextEditingController();
  var _draft = const PayoutAccountDraft();

  /// Null shows the saved account, when there is one.
  PayoutAccountStep? _step;
  var _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _accountNumber.dispose();
    _holderName.dispose();
    _holderEmail.dispose();
    _legalId.dispose();
    super.dispose();
  }

  List<PayoutAccountStep> get _steps => [
    PayoutAccountStep.method,
    if (_draft.method == PayoutMethod.bank) PayoutAccountStep.bank,
    PayoutAccountStep.destination,
    PayoutAccountStep.holder,
  ];

  double _progress(PayoutAccountStep step) =>
      (_steps.indexOf(step) + 1) / _steps.length;

  void _start() {
    final name = ref.read(providerProfileProvider).value?.party.displayName;
    final email = ref.read(accountEmailProvider);
    _phone.clear();
    _accountNumber.clear();
    _legalId.clear();
    _holderName.text = name ?? '';
    _holderEmail.text = email;
    setState(() {
      _draft = PayoutAccountDraft(holderName: name ?? '', holderEmail: email);
      _step = PayoutAccountStep.method;
    });
  }

  // Applied to the latest draft, so quick taps never undo one another.
  void _update(PayoutAccountDraft Function(PayoutAccountDraft) change) =>
      setState(() => _draft = change(_draft));

  void _next(PayoutAccountStep from) =>
      setState(() => _step = _steps[_steps.indexOf(from) + 1]);

  void _back(PayoutAccountStep from, PayoutAccount? saved) {
    final i = _steps.indexOf(from);
    if (i > 0) return setState(() => _step = _steps[i - 1]);
    if (saved != null) return setState(() => _step = null);
    context.pop();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final result = await ref
        .read(payoutActionsProvider.notifier)
        .register(_draft);
    if (result.isOk) await ref.read(payoutAccountProvider.future);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.isOk) _step = null;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(result.failureOrNull?.message ?? 'Cuenta guardada'),
        ),
      );
  }

  Future<void> _remove(PayoutAccount account) async {
    final confirmed = await showManoSheet<bool>(
      context: context,
      builder: (sheet) => ManoActionSheet(
        title: '¿Eliminar esta cuenta?',
        footnote: 'No te podremos pagar hasta que agregues otra.',
        onClose: () => Navigator.pop(sheet),
        actions: [
          ManoSheetAction(
            label: 'Eliminar',
            icon: Icons.delete_outline,
            onPressed: () => Navigator.pop(sheet, true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await ref
        .read(payoutActionsProvider.notifier)
        .remove(account.id);
    if (!mounted) return;
    if (result.failureOrNull case final failure?) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(payoutAccountProvider);
    if (!saved.hasValue) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cuenta para pagos')),
        body: saved.hasError
            ? ManoEmptyState(
                icon: Icons.cloud_off_outlined,
                message: 'No pudimos cargar tu cuenta',
                ctaLabel: 'Reintentar',
                onCta: () => ref.invalidate(payoutAccountProvider),
              )
            : const ManoSkeletonList(),
      );
    }
    final account = saved.value;
    if (_step == null && account != null) {
      return PayoutSummary(
        account: account,
        banks: ref.watch(payoutBanksProvider).value ?? const [],
        onChange: _start,
        onRemove: () => _remove(account),
      );
    }

    final step = _step ?? PayoutAccountStep.method;
    final leaves = step == PayoutAccountStep.method && account == null;
    return PopScope(
      canPop: leaves,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back(step, account);
      },
      child: ManoStepTransition(
        index: _steps.indexOf(step),
        child: KeyedSubtree(
          key: ValueKey(step),
          child: _question(step, account),
        ),
      ),
    );
  }

  Widget _question(PayoutAccountStep step, PayoutAccount? saved) {
    VoidCallback back() =>
        () => _back(step, saved);
    VoidCallback? next() => _draft.answers(step) ? () => _next(step) : null;
    return switch (step) {
      PayoutAccountStep.method => MethodStep(
        onBack: back(),
        onPick: (method) {
          _update((d) => d.copyWith(method: method));
          _next(step);
        },
      ),
      PayoutAccountStep.bank => BankStep(
        banks: ref.watch(payoutBanksProvider),
        onRetry: () => ref.invalidate(payoutBanksProvider),
        selectedCode: _draft.bankCode,
        progress: _progress(step),
        onPick: (code) => _update((d) => d.copyWith(bankCode: code)),
        onNext: next(),
        onBack: back(),
      ),
      PayoutAccountStep.destination => DestinationStep(
        draft: _draft,
        progress: _progress(step),
        phone: _phone,
        accountNumber: _accountNumber,
        onChanged: _update,
        onNext: next(),
        onBack: back(),
      ),
      PayoutAccountStep.holder => HolderStep(
        draft: _draft,
        progress: _progress(step),
        name: _holderName,
        email: _holderEmail,
        legalId: _legalId,
        busy: _busy,
        onChanged: _update,
        onSave: _draft.isValid && !_busy ? _save : null,
        onBack: back(),
      ),
    };
  }
}
