import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../onboarding_copy.dart';

/// Who you are and where you work.
class ProfileStep extends ConsumerStatefulWidget {
  const ProfileStep({required this.state, super.key});

  final ProviderOnboardingState state;

  @override
  ConsumerState<ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends ConsumerState<ProfileStep> {
  // Seeded once; resetting .text on every build would jump the cursor.
  late final _name = TextEditingController(text: widget.state.displayName);
  late final _phone = TextEditingController(text: widget.state.phone);
  late final _zone = TextEditingController(text: widget.state.workZone);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _zone.dispose();
    super.dispose();
  }

  ProviderOnboardingNotifier get _notifier =>
      ref.read(providerOnboardingProvider.notifier);

  void _next() {
    FocusScope.of(context).unfocus();
    _notifier.next();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    String? problem(
      ProfileProblem? Function(String) validate,
      String value,
      String Function(ProfileProblem) copy,
    ) {
      if (!s.showProblems) return null;
      final found = validate(value);
      return found == null ? null : copy(found);
    }

    return ManoStepScaffold(
      onBack: _notifier.back,
      headline: 'Tu perfil',
      subhead: 'Así te verán los clientes cuando tu cuenta esté aprobada.',
      primaryLabel: 'Continuar',
      onPrimary: _next,
      children: [
        ManoTextField(
          label: 'Nombre para mostrar',
          controller: _name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          errorText: problem(
            validateDisplayName,
            s.displayName,
            displayNameProblemCopy,
          ),
          onChanged: _notifier.editDisplayName,
        ),
        const SizedBox(height: ManoSpacing.lg),
        ManoTextField(
          label: 'Celular',
          controller: _phone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          errorText: problem(validatePhone, s.phone, phoneProblemCopy),
          onChanged: _notifier.editPhone,
        ),
        const SizedBox(height: ManoSpacing.lg),
        ManoTextField(
          label: 'Zona de cobertura',
          controller: _zone,
          helperText: 'Por ejemplo, Chapinero.',
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          errorText: problem(validateWorkZone, s.workZone, workZoneProblemCopy),
          onChanged: _notifier.editWorkZone,
          onSubmitted: (_) => _next(),
        ),
      ],
    );
  }
}
