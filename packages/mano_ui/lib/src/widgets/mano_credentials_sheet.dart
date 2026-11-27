import 'package:flutter/material.dart';

import '../icons/mano_envelope_icon.dart';
import '../theme/mano_theme.dart';
import 'mano_primary_button.dart';
import 'mano_outline_button.dart';
import 'mano_text_field.dart';

/// Email and password in a sheet; the caller signs in and closes it on success.
class ManoCredentialsSheet extends StatefulWidget {
  const ManoCredentialsSheet({
    required this.title,
    required this.submitLabel,
    required this.onSubmit,
    this.message,
    this.secondaryLabel,
    this.onSecondary,
    super.key,
  });

  final String title;
  final String? message;
  final String submitLabel;

  /// Resolves to an error to show, or `null` once it went through.
  final Future<String?> Function(String email, String password) onSubmit;

  /// A quieter way out under the button, e.g. creating an account instead.
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  State<ManoCredentialsSheet> createState() => _ManoCredentialsSheetState();
}

class _ManoCredentialsSheetState extends State<ManoCredentialsSheet> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _busy = false;
  String? _error;

  bool get _complete =>
      _email.text.trim().isNotEmpty && _password.text.isNotEmpty;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_complete) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onSubmit(_email.text.trim(), _password.text);
    if (mounted) {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          ManoSpacing.lg,
          ManoSpacing.lg,
          ManoSpacing.lg,
          ManoSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: theme.textTheme.headlineSmall),
              if (widget.message case final message?) ...[
                const SizedBox(height: ManoSpacing.xs),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.palette.muted,
                  ),
                ),
              ],
              const SizedBox(height: ManoSpacing.lg),
              ManoTextField(
                key: const Key('mano-credentials-email'),
                label: 'Correo',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                enabled: !_busy,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: ManoSpacing.md),
              ManoTextField(
                key: const Key('mano-credentials-password'),
                label: 'Contraseña',
                controller: _password,
                focusNode: _passwordFocus,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                enabled: !_busy,
                errorText: _error,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: ManoSpacing.lg),
              ManoPrimaryButton(
                label: widget.submitLabel,
                busy: _busy,
                onPressed: _complete ? _submit : null,
              ),
              if (widget.secondaryLabel case final label?) ...[
                const SizedBox(height: ManoSpacing.sm),
                ManoOutlineButton(
                  label: label,
                  leading: const ManoEnvelopeIcon(),
                  onPressed: _busy ? null : widget.onSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
