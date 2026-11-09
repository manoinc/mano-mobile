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

  /// What to say; the Spanish lives once, in `authFailureCopy`, for both apps.
  String _messageFor(AuthFailure failure) => authFailureCopy(failure);

  /// The domain says what went wrong; the screen decides how loudly to say
  /// it. Backing out is not an error, and must not be dressed as one.
  ManoNoticeTone _toneFor(AuthFailure failure) => switch (failure) {
    SignInCancelled() => ManoNoticeTone.info,
    SessionExpired() => ManoNoticeTone.warning,
    AuthUnavailable() => ManoNoticeTone.warning,
    TooManyAttempts() => ManoNoticeTone.warning,
    SignInRejected() ||
    WrongCredentials() ||
    EmailAlreadyRegistered() ||
    InvalidCode() ||
    CodeExpired() => ManoNoticeTone.error,
  };
}
