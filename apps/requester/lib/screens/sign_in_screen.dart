import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// The way in: the hero, a credentials sheet, and any failure carried by the session.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({required this.failure, super.key});

  final AuthFailure? failure;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  void _openSheet() {
    showManoSheet<void>(
      context: context,
      builder: (sheet) => ManoCredentialsSheet(
        title: 'Inicia sesión',
        message: 'Con el correo de tu cuenta Mano.',
        submitLabel: 'Entrar',
        onSubmit: (email, password) => _signIn(sheet, email, password),
      ),
    );
  }

  // Resolves to the copy to show inside the sheet, or closes it on success.
  Future<String?> _signIn(BuildContext sheet, String email, String password) async {
    // Captured first: a successful sign-in replaces this screen, and its ref with it.
    final session = ref.read(sessionProvider.notifier);
    final failure = await session.signIn(
      Credentials(email: email, password: password),
    );
    if (failure != null) {
      session.acknowledgeFailure();
      return _messageFor(failure);
    }
    if (sheet.mounted) Navigator.of(sheet).pop();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final failure = widget.failure;

    return ManoHeroScaffold(
      headline: 'Tu casa, en buenas manos.',
      primaryLabel: 'Iniciar sesión',
      onPrimary: _openSheet,
      notice: failure == null
          ? null
          : ManoNotice(
              message: _messageFor(failure),
              tone: _toneFor(failure),
              onDismiss: () =>
                  ref.read(sessionProvider.notifier).acknowledgeFailure(),
            ),
    );
  }

  /// What to say, in the voice the rest of the flow uses.
  ///
  /// `AuthFailure.message` exists and is in English, deliberately: it
  /// describes the failure for whoever is reading a log or a test, and
  /// `mano_domain` holds no user-facing copy and no locale. Spanish belongs
  /// here, next to the tone -- tuteo, short sentences, say what happened and
  /// what to do, never apologise.
  ///
  /// Exhaustive over the sealed class, so a fifth failure will not reach a
  /// user in English: it will fail to compile.
  String _messageFor(AuthFailure failure) => switch (failure) {
    SignInCancelled() => 'Cancelaste el inicio de sesión.',
    SessionExpired() => 'Tu sesión venció. Vuelve a iniciar sesión.',
    AuthUnavailable() =>
      'No pudimos conectar con el servicio de inicio de sesión. '
          'Vuelve a intentarlo en un momento.',
    SignInRejected() => 'Correo o contraseña incorrectos.',
  };

  /// The domain says what went wrong; the screen decides how loudly to say
  /// it. Backing out is not an error, and must not be dressed as one.
  ManoNoticeTone _toneFor(AuthFailure failure) => switch (failure) {
    SignInCancelled() => ManoNoticeTone.info,
    SessionExpired() => ManoNoticeTone.warning,
    AuthUnavailable() => ManoNoticeTone.warning,
    SignInRejected() => ManoNoticeTone.error,
  };
}
