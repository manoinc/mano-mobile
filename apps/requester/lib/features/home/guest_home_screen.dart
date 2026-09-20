import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../registration/welcome_overlay.dart';

/// Home, for somebody who has not signed in.
///
/// A placeholder with real shape: nothing here searches or books yet, but the
/// way back into an account is real, so "Omitir" is not a one-way door.
class GuestHomeScreen extends ConsumerStatefulWidget {
  const GuestHomeScreen({this.showWelcome = false, super.key});

  final bool showWelcome;

  @override
  ConsumerState<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends ConsumerState<GuestHomeScreen> {
  static const List<(IconData, String, String)> _categories = [
    (Icons.handyman_rounded, 'Reparaciones', 'Plomería, eléctrico y más'),
    (Icons.chair_rounded, 'Armado de muebles', 'Clósets, camas, escritorios'),
    (Icons.cleaning_services_rounded, 'Limpieza', 'Por horas o a fondo'),
    (Icons.tv_rounded, 'Instalaciones', 'TV, repisas, cortinas'),
    (Icons.local_florist_rounded, 'Jardinería', 'Poda y mantenimiento'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.showWelcome) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _welcome());
    }
  }

  Future<void> _welcome() async {
    if (!mounted) return;
    await showManoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WelcomeOverlay(
        onStart: () => Navigator.of(context).pop(),
      ),
    );
    if (!mounted) return;
    ref.read(onboardingFlowProvider.notifier).acknowledgeWelcome();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ManoLockup.inset,
                ManoSpacing.sm,
                ManoSpacing.sm,
                0,
              ),
              child: Row(
                children: [
                  const ManoWordmark(
                    height: ManoLockup.restingHeight,
                    color: ManoColors.flame,
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ManoTextAction(
                        label: 'Iniciar sesión',
                        onPressed: ref
                            .read(onboardingFlowProvider.notifier)
                            .startSignIn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ManoSpacing.lg,
                  ManoSpacing.md,
                  ManoSpacing.lg,
                  ManoSpacing.lg,
                ),
                children: [
                  const _SearchBox(),
                  const SizedBox(height: ManoSpacing.xl),
                  Text(
                    'Para tu hogar',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: ManoSpacing.md),
                  for (final (icon, title, detail) in _categories) ...[
                    ManoOptionRow(
                      icon: icon,
                      label: title,
                      detail: detail,
                      onPressed: () {},
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Looks like search, does nothing yet. There is no catalogue to search.
class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ManoSpacing.md,
        vertical: ManoSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(ManoRadius.card),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 20, color: ManoColors.faint),
          const SizedBox(width: ManoSpacing.sm),
          Expanded(
            child: Text(
              '¿Qué necesitas hacer?',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: ManoColors.faint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
