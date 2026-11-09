import 'package:flutter/material.dart';

import 'mano_brand_button.dart';

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
    final apple = switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };

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
