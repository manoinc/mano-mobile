import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// The price and an optional message; null when the sheet was closed.
Future<({int amountCop, String? message})?> showQuoteSheet(
  BuildContext context,
) => showManoSheet<({int amountCop, String? message})>(
  context: context,
  builder: (_) => const _QuoteSheet(),
);

class _QuoteSheet extends StatefulWidget {
  const _QuoteSheet();

  @override
  State<_QuoteSheet> createState() => _QuoteSheetState();
}

class _QuoteSheetState extends State<_QuoteSheet> {
  final _message = TextEditingController();
  int? _amount;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _send() {
    final message = _message.text.trim();
    Navigator.pop(context, (
      amountCop: _amount!,
      message: message.isEmpty ? null : message,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            ManoSpacing.lg,
            ManoSpacing.md,
            ManoSpacing.lg,
            ManoSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tu cotización',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: ManoSpacing.md),
              ManoAmountPad(
                amountLabel: ManoFormat.cop(_amount ?? 0),
                helperText: 'Cotizar es gratis por ahora.',
                onDigit: (digits) =>
                    setState(() => _amount = typeAmount(_amount, digits)),
                onBackspace: () =>
                    setState(() => _amount = eraseAmount(_amount)),
              ),
              const SizedBox(height: ManoSpacing.md),
              ManoTextField(
                label: 'Mensaje (opcional)',
                controller: _message,
                textCapitalization: TextCapitalization.sentences,
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: ManoSpacing.lg),
              ManoPrimaryButton(
                label: 'Enviar cotización',
                onPressed: _amount == null ? null : _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
