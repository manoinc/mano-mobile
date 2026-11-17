import 'package:flutter/material.dart';

import '../icons/mano_envelope_icon.dart';
import '../theme/mano_theme.dart';
import 'mano_brand_pill_row.dart';
import 'mano_country_picker_sheet.dart';
import 'mano_otp_field.dart';
import 'mano_phone_field.dart';
import 'mano_platform_sign_in_button.dart';
import 'mano_resend_timer.dart';
import 'mano_sheet.dart';
import 'mano_sign_in_layout.dart';

/// The one sign-in screen both apps show: country and number, then the code.
class ManoPhoneSignInScreen extends StatefulWidget {
  const ManoPhoneSignInScreen({
    required this.countries,
    required this.countryCode,
    required this.onCountrySelected,
    required this.phone,
    required this.onPhoneChanged,
    required this.onSendCode,
    required this.onTrouble,
    required this.googleMark,
    required this.appleMark,
    required this.onGoogle,
    required this.onApple,
    required this.onEmail,
    required this.onClose,
    required this.codeSentTo,
    required this.code,
    required this.onCodeChanged,
    required this.onVerify,
    required this.canVerify,
    required this.onResend,
    required this.onChangeNumber,
    this.busy = false,
    this.phoneError,
    this.codeError,
    this.notice,
    this.title = 'Inicia sesión o regístrate',
    super.key,
  });

  final List<ManoCountryOption> countries;
  final String countryCode;
  final ValueChanged<String> onCountrySelected;

  /// The number as typed; seeds the field once.
  final String phone;
  final ValueChanged<String> onPhoneChanged;
  final VoidCallback onSendCode;

  /// "¿Problemas para entrar?".
  final VoidCallback onTrouble;

  /// App assets; Google shows on Android, Apple on iOS.
  final Widget googleMark;
  final Widget appleMark;
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  final VoidCallback? onEmail;
  final VoidCallback? onClose;

  /// The masked number once a code is sent; switches to the code step.
  final String? codeSentTo;
  final String code;
  final ValueChanged<String> onCodeChanged;

  /// Also called on the sixth digit, so it must check the code itself.
  final VoidCallback onVerify;

  /// Enables Continuar on the code step.
  final bool canVerify;
  final VoidCallback onResend;
  final VoidCallback onChangeNumber;
  final bool busy;
  final String? phoneError;
  final String? codeError;

  /// A failure the field cannot carry, e.g. the server being down.
  final Widget? notice;
  final String title;

  @override
  State<ManoPhoneSignInScreen> createState() => _ManoPhoneSignInScreenState();
}

class _ManoPhoneSignInScreenState extends State<ManoPhoneSignInScreen> {
  late final _phone = TextEditingController(text: widget.phone);

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  ManoCountryOption get _country => widget.countries.firstWhere(
    (c) => c.code == widget.countryCode,
    orElse: () => widget.countries.first,
  );

  void _pickCountry() => showManoSheet<void>(
    context: context,
    builder: (sheet) => ManoCountryPickerSheet(
      countries: widget.countries,
      selectedCode: widget.countryCode,
      onClose: () => Navigator.of(sheet).pop(),
      onSelected: (code) {
        Navigator.of(sheet).pop();
        widget.onCountrySelected(code);
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final sentTo = w.codeSentTo;

    if (sentTo != null) {
      return ManoSignInLayout(
        key: const ValueKey('code'),
        title: 'Confirma tu número',
        message: 'Escribe el código que enviamos a $sentTo.',
        onClose: w.onChangeNumber,
        busy: w.busy,
        notice: w.notice,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ManoOtpField(
              value: w.code,
              autofocus: true,
              enabled: !w.busy,
              errorText: w.codeError,
              onChanged: w.onCodeChanged,
              onCompleted: (_) => w.onVerify(),
            ),
            const SizedBox(height: ManoSpacing.md),
            ManoResendTimer(onResend: w.onResend, enabled: !w.busy),
          ],
        ),
        primaryLabel: 'Continuar',
        onPrimary: w.canVerify ? w.onVerify : null,
      );
    }

    final apple = manoSignsInWithApple(Theme.of(context).platform);
    final country = _country;
    return ManoSignInLayout(
      key: const ValueKey('phone'),
      title: w.title,
      onClose: w.onClose,
      busy: w.busy,
      notice: w.notice,
      body: ManoPhoneField(
        controller: _phone,
        countryFlag: country.flag,
        country: '${country.name} (${country.dialCode})',
        onCountryTap: w.busy ? null : _pickCountry,
        enabled: !w.busy,
        helperText: 'Te enviaremos un código por WhatsApp.',
        errorText: w.phoneError,
        onChanged: w.onPhoneChanged,
        onSubmitted: (_) => w.onSendCode(),
      ),
      primaryLabel: 'Continuar',
      onPrimary: w.busy ? null : w.onSendCode,
      linkLabel: '¿Problemas para entrar?',
      onLink: w.onTrouble,
      footerLabel: 'O continúa con',
      footer: ManoBrandPillRow(
        pills: [
          apple
              ? ManoBrandPill(
                  mark: w.appleMark,
                  label: 'Continuar con Apple',
                  onPressed: w.busy ? null : w.onApple,
                )
              : ManoBrandPill(
                  mark: w.googleMark,
                  label: 'Continuar con Google',
                  onPressed: w.busy ? null : w.onGoogle,
                ),
          ManoBrandPill(
            mark: const ManoEnvelopeIcon(size: 22),
            label: 'Continuar con correo',
            onPressed: w.busy ? null : w.onEmail,
          ),
        ],
      ),
    );
  }
}
