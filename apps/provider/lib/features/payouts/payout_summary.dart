import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'payout_labels.dart';

/// The saved payout account, masked, with change and remove.
class PayoutSummary extends StatelessWidget {
  const PayoutSummary({
    required this.account,
    required this.banks,
    required this.onChange,
    required this.onRemove,
    super.key,
  });

  final PayoutAccount account;
  final List<Bank> banks;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final destination = account.destination;
    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta para pagos')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ManoSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(ManoSpacing.md),
                decoration: BoxDecoration(
                  color: ManoColors.sand,
                  borderRadius: BorderRadius.circular(ManoRadius.card),
                ),
                child: Row(
                  children: [
                    ManoPaymentLogo(
                      logo: switch (payoutLogoAsset(destination, banks)) {
                        final String asset => Image.asset(asset),
                        null => null,
                      },
                      fallback: const Icon(
                        Icons.account_balance_outlined,
                        color: ManoColors.clay,
                      ),
                    ),
                    const SizedBox(width: ManoSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            destinationTitle(destination, banks),
                            style: text.titleMedium,
                          ),
                          Text(
                            destinationDetail(destination),
                            style: text.bodyMedium?.copyWith(
                              color: ManoColors.muted,
                            ),
                          ),
                          const SizedBox(height: ManoSpacing.xs),
                          Text(
                            holderLine(account.holder),
                            style: text.bodySmall?.copyWith(
                              color: ManoColors.faint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ManoSpacing.md),
              Text(
                'Aquí te pagamos lo que ganas con tus trabajos.',
                style: text.bodySmall?.copyWith(color: ManoColors.faint),
              ),
              const Spacer(),
              ManoPrimaryButton(label: 'Cambiar cuenta', onPressed: onChange),
              const SizedBox(height: ManoSpacing.sm),
              ManoQuietButton(label: 'Eliminar cuenta', onPressed: onRemove),
            ],
          ),
        ),
      ),
    );
  }
}
