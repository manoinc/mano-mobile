import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../activity/load_error.dart';
import 'payment_method_form_sheet.dart';
import 'profile_copy.dart';
import 'profile_sheets.dart';

enum _MethodAction { makeDefault, remove }

IconData _iconFor(PaymentKind kind) => switch (kind) {
  PaymentKind.card => Icons.credit_card,
  PaymentKind.nequi => Icons.account_balance_wallet_outlined,
  PaymentKind.pse => Icons.account_balance_outlined,
};

/// Métodos de pago: saved cards and Nequi, display data only.
class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  PaymentMethodActions _actions(WidgetRef ref) =>
      ref.read(paymentMethodActionsProvider.notifier);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methods = ref.watch(savedPaymentMethodsProvider);
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
    const notice = ManoNotice(
      message:
          'Aún no cobramos desde la app. Guarda tus métodos y te avisaremos '
          'cuando los pagos estén activos.',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Métodos de pago')),
      body: switch (methods) {
        AsyncData(value: final list) => ListView(
          padding: const EdgeInsets.all(ManoSpacing.lg),
          children: [
            notice,
            const SizedBox(height: ManoSpacing.md),
            if (list.isEmpty)
              ManoEmptyState(
                icon: Icons.credit_card,
                message: 'Agrega una tarjeta o tu Nequi para pagar más rápido.',
                ctaLabel: 'Agregar método de pago',
                onCta: () => _add(context, ref),
              )
            else ...[
              for (final method in list) ...[
                ManoOptionRow(
                  key: Key('payment-${method.id}'),
                  icon: _iconFor(method.kind),
                  label: paymentMethodTitle(method),
                  tag: method.isDefault ? 'Predeterminado' : null,
                  onPressed: () => _open(context, ref, method),
                ),
                divider,
              ],
              const SizedBox(height: ManoSpacing.lg),
              ManoOutlineButton(
                label: 'Agregar método de pago',
                onPressed: () => _add(context, ref),
              ),
            ],
          ],
        ),
        AsyncError() => ActivityLoadError(
          message: 'No pudimos cargar tus métodos de pago.',
          onRetry: () => ref.invalidate(savedPaymentMethodsProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final kind = await chooseAction<PaymentKind>(
      context,
      title: 'Agregar método de pago',
      choices: const [
        (PaymentKind.card, 'Tarjeta', Icons.credit_card),
        (PaymentKind.nequi, 'Nequi', Icons.account_balance_wallet_outlined),
      ],
    );
    if (kind == null || !context.mounted) return;
    final method = await showPaymentMethodForm(context, kind);
    if (method == null || !context.mounted) return;
    final result = await _actions(ref).add(method);
    if (context.mounted) _report(context, result);
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    PaymentMethod method,
  ) async {
    final action = await chooseAction<_MethodAction>(
      context,
      title: paymentMethodTitle(method),
      choices: [
        if (!method.isDefault)
          (
            _MethodAction.makeDefault,
            'Usar como predeterminado',
            Icons.check_circle_outline,
          ),
        (_MethodAction.remove, 'Eliminar', Icons.delete_outline),
      ],
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _MethodAction.makeDefault:
        final result = await _actions(ref).setDefault(method.id);
        if (context.mounted) _report(context, result);
      case _MethodAction.remove:
        final sure = await confirmRemove(
          context,
          title: '¿Eliminar ${paymentMethodTitle(method)}?',
          message: 'Puedes agregarlo de nuevo cuando quieras.',
        );
        if (!sure || !context.mounted) return;
        final result = await _actions(ref).remove(method.id);
        if (context.mounted) _report(context, result);
    }
  }

  void _report(BuildContext context, Result<Object?, DataFailure> result) {
    if (result case Err(:final failure)) {
      showProfileMessage(context, failure.message);
    }
  }
}
