import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

class ProfessionalOnboardingScreen extends StatelessWidget {
  const ProfessionalOnboardingScreen({required this.onFinished, super.key});

  /// Enters the shell; local only until a real auth backend exists.
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    return ManoHeroScaffold(
      headline: 'PROV-01 · Registro profesional',
      primaryLabel: 'Continuar',
      onPrimary: onFinished,
    );
  }
}
