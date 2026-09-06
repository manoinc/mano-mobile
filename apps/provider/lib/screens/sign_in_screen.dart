import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Where a Proveedor signs in.
///
/// The screen is the only layer that knows both halves: it reads domain
/// failures and speaks to `mano_ui` in strings and callbacks. That translation
/// is its whole job, and it is why widgets below stay reusable.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({required this.failure, required this.busy, super.key});

  /// The reason the last attempt did not succeed, if the user has not been
  /// told yet.
  final AuthFailure? failure;

  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notice = failure;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ManoSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Mano Pro', style: theme.textTheme.displaySmall),
              const SizedBox(height: ManoSpacing.sm),
              Text(
                'Recibe solicitudes de trabajo cerca de ti.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: ManoSpacing.xl),

              if (notice != null) ...[
                ManoNotice(
                  // The mapping happens here: a sealed domain failure becomes
                  // a string and a tone. `mano_ui` never sees an AuthFailure.
                  message: notice.message,
                  tone: _toneFor(notice),
                  onDismiss: () =>
                      ref.read(sessionProvider.notifier).acknowledgeFailure(),
                ),
                const SizedBox(height: ManoSpacing.lg),
              ],

              ManoPrimaryButton(
                label: 'Iniciar sesión',
                busy: busy,
                onPressed: () => ref.read(sessionProvider.notifier).signIn(),
              ),
              const SizedBox(height: ManoSpacing.md),
              Text(
                'Se abrirá tu navegador para completar el inicio de sesión.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// How loudly each failure should read.
  ///
  /// A cancelled sign-in is not an error and must not look like one: the user
  /// pressed back on purpose. The switch is exhaustive, so a new failure case
  /// cannot be added without deciding how it appears here.
  ManoNoticeTone _toneFor(AuthFailure failure) => switch (failure) {
    SignInCancelled() => ManoNoticeTone.info,
    SessionExpired() => ManoNoticeTone.warning,
    AuthUnavailable() => ManoNoticeTone.warning,
    SignInRejected() => ManoNoticeTone.error,
  };
}
