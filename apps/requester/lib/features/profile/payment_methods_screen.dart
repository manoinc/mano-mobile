import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

String _detailFor(PaymentKind kind) => switch (kind) {
  PaymentKind.card => 'Tarjeta',
  PaymentKind.nequi => 'Billetera Nequi',
  PaymentKind.pse => 'Débito desde tu banco',
};

/// Métodos de pago, Airbnb-style: title, saved methods with Editar, an ink add pill and the Mano promise.
class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  PaymentMethodActions _actions(WidgetRef ref) =>
      ref.read(paymentMethodActionsProvider.notifier);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final methods = ref.watch(savedPaymentMethodsProvider);
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: theme.colorScheme.outlineVariant,
    );

    return Scaffold(
      appBar: AppBar(),
      body: switch (methods) {
        AsyncData(value: final list) => ListView(
          padding: const EdgeInsets.fromLTRB(
            ManoSpacing.lg,
            0,
            ManoSpacing.lg,
            ManoSpacing.lg,
          ),
          children: [
            Text('Métodos de pago', style: theme.textTheme.headlineMedium),
            const SizedBox(height: ManoSpacing.xs),
            Text(
              'Guarda tus métodos para pagar más rápido cuando termine un '
              'trabajo.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: ManoSpacing.lg),
            for (final method in list) ...[
              ManoMethodRow(
                key: Key('payment-${method.id}'),
                leading: Icon(_iconFor(method.kind)),
                title: paymentMethodTitle(method),
                detail: _detailFor(method.kind),
                tag: method.isDefault ? 'Predeterminado' : null,
                actionLabel: 'Editar',
                onAction: () => _open(context, ref, method),
              ),
              divider,
            ],
            if (list.isNotEmpty) const SizedBox(height: ManoSpacing.lg),
            ManoPrimaryButton(
              label: 'Agregar método de pago',
              tone: ManoPrimaryTone.ink,
              onPressed: () => _add(context, ref),
            ),
            const SizedBox(height: ManoSpacing.xl),
            ManoInfoCard(
              icon: Icons.verified_user_outlined,
              title: 'Paga siempre a través de Mano',
              message:
                  'Si pagas por fuera de la app, no podemos ayudarte con '
                  'reclamos ni reembolsos. Pagando en Mano tu dinero queda '
                  'protegido.',
              linkLabel: 'Más información',
              onLink: () => context.push('/profile/support'),
            ),
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
