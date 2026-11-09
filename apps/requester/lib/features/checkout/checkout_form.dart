import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'checkout_labels.dart';
import 'checkout_pse_fields.dart';

/// Airbnb's "Confirmar y pagar": the job, the price, how to pay, and the terms.
class CheckoutForm extends ConsumerWidget {
  const CheckoutForm({
    required this.job,
    required this.draft,
    required this.phone,
    required this.legalId,
    required this.email,
    required this.onChanged,
    super.key,
  });

  final Job job;
  final JobPaymentDraft draft;
  final TextEditingController phone;
  final TextEditingController legalId;
  final TextEditingController email;
  final ValueChanged<JobPaymentDraft Function(JobPaymentDraft)> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final heading = theme.textTheme.titleMedium;
    final terms = ref.watch(jobCheckoutTermsProvider).value ?? const [];
    final opener = ref.read(externalLinkOpenerProvider);
    final total = ManoFormat.cop(job.payableCop);
    void pick(JobPaymentMethod method) =>
        onChanged((d) => d.copyWith(method: method));

    return ListView(
      padding: const EdgeInsets.all(ManoSpacing.lg),
      children: [
        _JobSummary(job: job),
        const SizedBox(height: ManoSpacing.lg),
        ManoPriceBreakdown(
          title: 'Detalle del precio',
          lines: [(priceLine(job), total)],
          totalLabel: 'Total (COP)',
          totalValue: total,
        ),
        const SizedBox(height: ManoSpacing.xl),
        Text('Método de pago', style: heading),
        const SizedBox(height: ManoSpacing.md),
        ManoMethodOption(
          leading: const Icon(Icons.phone_iphone),
          title: 'Nequi',
          detail: 'Apruebas el pago en tu celular',
          selected: draft.method == JobPaymentMethod.nequi,
          onTap: () => pick(JobPaymentMethod.nequi),
        ),
        const SizedBox(height: ManoSpacing.sm),
        ManoMethodOption(
          leading: const Icon(Icons.account_balance_outlined),
          title: 'PSE',
          detail: 'Pagas desde tu banco',
          selected: draft.method == JobPaymentMethod.pse,
          onTap: () => pick(JobPaymentMethod.pse),
        ),
        const SizedBox(height: ManoSpacing.sm),
        const ManoMethodOption(
          leading: Icon(Icons.credit_card),
          title: 'Tarjeta',
          tag: 'Próximamente',
          selected: false,
          onTap: null,
        ),
        const SizedBox(height: ManoSpacing.md),
        ...switch (draft.method) {
          JobPaymentMethod.nequi => [
            ManoTextField(
              label: 'Celular de Nequi',
              controller: phone,
              keyboardType: TextInputType.phone,
              helperText: 'Te llega una notificación para aprobar el pago.',
              errorText: checkoutPhoneError(draft),
              onChanged: (v) => onChanged((d) => d.copyWith(phone: v)),
            ),
            const SizedBox(height: ManoSpacing.md),
          ],
          JobPaymentMethod.pse => [
            CheckoutPseFields(
              draft: draft,
              banks: ref.watch(jobPseBanksProvider).value ?? const [],
              legalId: legalId,
              onChanged: onChanged,
            ),
            const SizedBox(height: ManoSpacing.md),
          ],
          null => const <Widget>[],
        },
        ManoTextField(
          label: 'Correo para el recibo',
          controller: email,
          keyboardType: TextInputType.emailAddress,
          errorText: checkoutEmailError(draft),
          onChanged: (v) => onChanged((d) => d.copyWith(payerEmail: v)),
        ),
        const SizedBox(height: ManoSpacing.lg),
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
      ],
    );
  }
}

class _JobSummary extends StatelessWidget {
  const _JobSummary({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final provider = job.provider.displayName.isEmpty
        ? 'Tu profesional'
        : job.provider.displayName;
    return Row(
      children: [
        ManoAvatar(photoUrl: job.provider.photoUrl, size: 56),
        const SizedBox(width: ManoSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(job.serviceTitle, style: textTheme.titleMedium),
              Text(
                '$provider · ${ManoFormat.weekdayShort(job.start)} '
                '${ManoFormat.dayMonth(job.start)}',
                style: textTheme.bodySmall?.copyWith(color: ManoColors.faint),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
