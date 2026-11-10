import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../onboarding_copy.dart';
import '../sign_in_sheet.dart';
import '../widgets/google_mark.dart';

/// The shared phone sign-in, routed through this app's onboarding.
class SignInStep extends ConsumerWidget {
  const SignInStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(phoneSignInProvider);
    final phone = ref.read(phoneSignInProvider.notifier);
    final onboarding = ref.read(providerOnboardingProvider.notifier);
    final failure = state.failure;
    final codeStep = state.challenge != null;

    // A new account continues at the identity check; a returning one enters the shell.
    void enter(Session? session, {String? number}) {
      if (session != null) onboarding.enter(session, phone: number);
    }

    void openEmail() =>
        showSignInSheet(context, ref, onCreateAccount: onboarding.start);

    return ManoPhoneSignInScreen(
      countries: [
        for (final c in supportedCountries)
          ManoCountryOption(
            code: c.code,
            flag: c.flag,
            name: c.name,
            dialCode: '+${c.dialCode}',
          ),
      ],
      countryCode: state.country.code,
      onCountrySelected: (code) => phone.selectCountry(countryByCode(code)!),
      phone: state.phone,
      onPhoneChanged: phone.editPhone,
      onSendCode: phone.sendCode,
      onTrouble: openEmail,
      googleMark: const GoogleMark(),
      appleMark: const Icon(Icons.apple, size: 22),
      onGoogle: () async =>
          enter(await phone.signInWith(SocialProvider.google)),
      onApple: () async => enter(await phone.signInWith(SocialProvider.apple)),
      onEmail: openEmail,
      onClose: onboarding.back,
      codeSentTo: state.challenge?.maskedPhone,
      code: state.code,
      onCodeChanged: phone.editCode,
      onVerify: () async {
        final number = ref.read(phoneSignInProvider).e164;
        enter(await phone.verify(), number: number);
      },
      canVerify: state.canVerify,
      onResend: phone.resend,
      onChangeNumber: phone.changeNumber,
      busy: state.busy,
      phoneError: state.showPhoneProblem
          ? phoneNumberProblemCopy(state.country)
          : null,
      codeError: codeStep && failure != null ? authFailureCopy(failure) : null,
      notice: codeStep || failure == null
          ? null
          : ManoNotice(
              message: authFailureCopy(failure),
              tone: authFailureTone(failure),
              onDismiss: phone.acknowledgeFailure,
            ),
    );
  }
}
