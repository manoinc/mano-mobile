import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_primary_button.dart';
import 'mano_text_field.dart';

/// "Escribir a soporte": a subject and what happened, shared by both apps.
class ManoSupportForm extends StatefulWidget {
  const ManoSupportForm({
    required this.onSubmit,
    this.subjectError,
    this.descriptionError,
    this.sending = false,
    super.key,
  });

  final void Function(String subject, String description) onSubmit;
  final String? subjectError;
  final String? descriptionError;
  final bool sending;

  @override
  State<ManoSupportForm> createState() => _ManoSupportFormState();
}

class _ManoSupportFormState extends State<ManoSupportForm> {
  final _subject = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ManoTextField(
          label: 'Asunto',
          controller: _subject,
          errorText: widget.subjectError,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: ManoSpacing.lg),
        ManoTextField(
          label: 'Cuéntanos qué pasó',
          controller: _description,
          errorText: widget.descriptionError,
          helperText: 'Incluye fechas, el servicio y el profesional si aplica.',
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          minLines: 4,
          maxLines: 8,
        ),
        const SizedBox(height: ManoSpacing.xl),
        ManoPrimaryButton(
          label: 'Enviar',
          busy: widget.sending,
          onPressed: () => widget.onSubmit(_subject.text, _description.text),
        ),
      ],
    );
  }
}
