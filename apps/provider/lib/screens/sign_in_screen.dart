import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// The way in.
///
/// Deliberately minimal: one action, wired to [SessionRepository] through
/// [sessionProvider] and nothing else. What that action actually does --
/// raise a native form, hand off to a browser, launch a platform sign-in
/// SDK -- is entirely the adapter's business, chosen once an auth provider
/// is. This screen doesn't know, and doesn't need to: it renders the brand,
/// asks the session to sign in, and shows whatever [AuthFailure] comes back.
///
/// "Waiting for sign-in" is held here rather than in the session, as local
/// [_busy] state. It's a fact about this screen's button, not about the
/// session, and keeping it here is what stops a slow sign-in from blanking
/// the rest of the app.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({required this.failure, super.key});

  final AuthFailure? failure;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(sessionProvider.notifier).signIn();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final failure = widget.failure;

    return ManoHeroScaffold(
      headline: 'Tu trabajo, más cerca.',
      primaryLabel: 'Iniciar sesión',
      onPrimary: _signIn,
      busy: _busy,
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
    SignInRejected() =>
      'No pudimos completar el inicio de sesión. Vuelve a intentarlo.',
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
