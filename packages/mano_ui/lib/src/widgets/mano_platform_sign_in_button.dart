import 'package:flutter/material.dart';

import 'mano_brand_button.dart';

/// Whether [platform] signs in with Apple rather than Google.
bool manoSignsInWithApple(TargetPlatform platform) => switch (platform) {
  TargetPlatform.iOS || TargetPlatform.macOS => true,
  _ => false,
};

/// Sign in with the platform's own identity: Apple on iOS, Google elsewhere.
class ManoPlatformSignInButton extends StatelessWidget {
  const ManoPlatformSignInButton({
    required this.googleMark,
    required this.appleMark,
    required this.onGoogle,
    required this.onApple,
    super.key,
  });

  final Widget googleMark;
  final Widget appleMark;
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;

  @override
  Widget build(BuildContext context) {
    final apple = manoSignsInWithApple(Theme.of(context).platform);

    return apple
        ? ManoBrandButton(
            label: 'Continuar con Apple',
            leading: appleMark,
            onPressed: onApple,
          )
        : ManoBrandButton(
            label: 'Continuar con Google',
            leading: googleMark,
            onPressed: onGoogle,
          );
  }
}
