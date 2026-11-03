import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'profile_copy.dart';

/// Opens the form for [kind]; resolves to what was typed, or null.
Future<NewPaymentMethod?> showPaymentMethodForm(
  BuildContext context,
  PaymentKind kind,
) => showManoSheet<NewPaymentMethod>(
  context: context,
  builder: (_) => PaymentMethodFormSheet(kind: kind),
);

/// A card (number and expiry) or a Nequi number; nothing else is asked.
class PaymentMethodFormSheet extends StatefulWidget {
  const PaymentMethodFormSheet({required this.kind, super.key});

  final PaymentKind kind;

  @override
  State<PaymentMethodFormSheet> createState() => _PaymentMethodFormSheetState();
}

class _PaymentMethodFormSheetState extends State<PaymentMethodFormSheet> {
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _phone = TextEditingController();
  Map<PaymentField, FieldProblem> _problems = const {};

  bool get _isCard => widget.kind == PaymentKind.card;

  @override
  void dispose() {
    _number.dispose();
    _expiry.dispose();
    _phone.dispose();
    super.dispose();
  }

  NewPaymentMethod get _draft => _isCard
      ? NewCard(number: _number.text, expiry: _expiry.text)
      : NewNequi(phone: _phone.text);

  String? _error(PaymentField field, String name) => switch (_problems[field]) {
    final FieldProblem p => problemCopy(p, field: name),
    _ => null,
  };

  void _save() {
    final draft = _draft;
    final problems = draft.problems(DateTime.now());
    if (problems.isEmpty) {
      Navigator.pop(context, draft);
    } else {
      setState(() => _problems = problems);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ManoSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isCard ? 'Agregar tarjeta' : 'Agregar Nequi',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: ManoSpacing.lg),
              if (_isCard) ...[
                ManoTextField(
                  label: 'Número de tarjeta',
                  controller: _number,
                  errorText: _error(
                    PaymentField.cardNumber,
                    'el número de la tarjeta',
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.creditCardNumber],
                ),
                const SizedBox(height: ManoSpacing.md),
                ManoTextField(
                  label: 'Vence (MM/AA)',
                  controller: _expiry,
                  errorText: _error(PaymentField.expiry, 'la fecha'),
                  keyboardType: TextInputType.datetime,
                  autofillHints: const [AutofillHints.creditCardExpirationDate],
                ),
              ] else
                ManoTextField(
                  label: 'Celular de Nequi',
                  controller: _phone,
                  errorText: _error(PaymentField.phone, 'tu celular'),
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                ),
              const SizedBox(height: ManoSpacing.md),
              Text(
                'Solo guardamos los últimos 4 dígitos.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ManoColors.faint,
                ),
              ),
              const SizedBox(height: ManoSpacing.xl),
              ManoPrimaryButton(label: 'Guardar', onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
