import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'pse_fields.dart';
import 'purchase_labels.dart';
import 'wallet_labels.dart';

/// Airbnb-style checkout in one sheet: pack, method, terms, then one pay button.
class PurchaseForm extends ConsumerWidget {
  const PurchaseForm({
    required this.draft,
    required this.phone,
    required this.legalId,
    required this.email,
    required this.askEmail,
    required this.busy,
    required this.onChanged,
    required this.onPay,
    super.key,
  });

  final CoinPurchaseDraft draft;
  final TextEditingController phone;
  final TextEditingController legalId;
  final TextEditingController email;

  /// Only when the account has no usable email to send the receipt to.
  final bool askEmail;
  final bool busy;
  final ValueChanged<CoinPurchaseDraft Function(CoinPurchaseDraft)> onChanged;
  final ValueChanged<CoinPack> onPay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final caption = theme.textTheme.labelMedium?.copyWith(
      color: context.palette.faint,
    );
    final packs = ref.watch(coinPacksProvider).value ?? const <CoinPack>[];
    final terms = ref.watch(checkoutTermsProvider).value ?? const [];
    final opener = ref.read(externalLinkOpenerProvider);
    final selected = packs.where((p) => p.id == draft.packId).firstOrNull;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Recargar coins', style: theme.textTheme.headlineSmall),
        const SizedBox(height: ManoSpacing.md),
        if (packs.isEmpty && ref.watch(coinPacksProvider).hasError)
          ManoNotice(
            message: 'No pudimos cargar los paquetes.',
            tone: ManoNoticeTone.error,
            onDismiss: () => ref.invalidate(coinPacksProvider),
          ),
        for (final pack in packs) ...[
          ManoPackOption(
            coinsLabel: coinsLabel(pack.coins),
            priceLabel: ManoFormat.cop(pack.priceCop),
            bonusLabel: pack.bonus > 0 ? '+${pack.bonus} gratis' : null,
            selected: pack.id == selected?.id,
            onTap: () => onChanged((d) => d.copyWith(packId: pack.id)),
          ),
          const SizedBox(height: ManoSpacing.sm),
        ],
        const SizedBox(height: ManoSpacing.md),
        Text('Cómo quieres pagar', style: caption),
        const SizedBox(height: ManoSpacing.sm),
        Wrap(
          spacing: ManoSpacing.sm,
          children: [
            for (final method in CoinPurchaseMethod.values)
              ManoChoiceChip(
                label: methodLabel(method),
                selected: draft.method == method,
                onTap: () => onChanged((d) => d.copyWith(method: method)),
              ),
          ],
        ),
        const SizedBox(height: ManoSpacing.md),
        ...switch (draft.method) {
          CoinPurchaseMethod.nequi => [
            ManoTextField(
              label: 'Celular de Nequi',
              controller: phone,
              keyboardType: TextInputType.phone,
              helperText: 'Te llega una notificación para aprobar el pago.',
              errorText: purchasePhoneError(draft),
              onChanged: (v) => onChanged((d) => d.copyWith(phone: v)),
            ),
          ],
          CoinPurchaseMethod.pse => [
            PseFields(
              draft: draft,
              banks: ref.watch(pseBanksProvider).value ?? const [],
              legalId: legalId,
              onChanged: onChanged,
            ),
          ],
          null => const <Widget>[],
        },
        if (askEmail) ...[
          const SizedBox(height: ManoSpacing.md),
          ManoTextField(
            label: 'Correo para el recibo',
            controller: email,
            keyboardType: TextInputType.emailAddress,
            errorText: payerEmailError(draft),
            onChanged: (v) => onChanged((d) => d.copyWith(payerEmail: v)),
          ),
        ],
        const SizedBox(height: ManoSpacing.md),
        ManoToggleRow(
          label: 'Acepto los términos de pago',
          value: draft.termsAccepted,
          onChanged: (v) => onChanged((d) => d.copyWith(termsAccepted: v)),
        ),
        Wrap(
          children: [
            for (final term in terms)
              ManoTextAction(
                label: term.label,
                padding: const EdgeInsets.symmetric(vertical: ManoSpacing.sm),
                onPressed: () => opener(Uri.parse(term.url)),
              ),
          ],
        ),
        const SizedBox(height: ManoSpacing.sm),
        ManoPrimaryButton(
          label: selected == null
              ? 'Pagar'
              : 'Pagar · ${ManoFormat.cop(selected.priceCop)}',
          busy: busy,
          onPressed: selected != null && draft.isValid && !busy
              ? () => onPay(selected)
              : null,
        ),
      ],
    );
  }
}
