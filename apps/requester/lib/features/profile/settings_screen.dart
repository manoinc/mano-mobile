import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../config.dart';

/// Configuración: local notification toggles, language, terms and version.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);
    final theme = Theme.of(context);
    const gap = SizedBox(height: ManoSpacing.sm);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(ManoSpacing.lg),
        children: [
          Text('Notificaciones', style: theme.textTheme.titleMedium),
          const SizedBox(height: ManoSpacing.md),
          ManoToggleRow(
            label: 'Actualizaciones de tus trabajos',
            value: prefs.jobUpdates,
            onChanged: notifier.setJobUpdates,
          ),
          gap,
          ManoToggleRow(
            label: 'Mensajes',
            value: prefs.messages,
            onChanged: notifier.setMessages,
          ),
          gap,
          ManoToggleRow(
            label: 'Promociones y novedades',
            value: prefs.promotions,
            onChanged: notifier.setPromotions,
          ),
          const SizedBox(height: ManoSpacing.lg),
          const ManoOptionRow(
            icon: Icons.language,
            label: 'Idioma',
            detail: 'Español',
            onPressed: null,
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          ManoOptionRow(
            icon: Icons.description_outlined,
            label: 'Términos y privacidad',
            onPressed: () => _showTerms(context),
          ),
          const SizedBox(height: ManoSpacing.xl),
          Text(
            'Versión $requesterAppVersion',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: ManoColors.faint),
          ),
        ],
      ),
    );
  }

  void _showTerms(BuildContext context) => showManoSheet<void>(
    context: context,
    builder: (sheet) => ManoPromptSheet(
      title: 'Términos y privacidad',
      message:
          'Publicaremos aquí los términos de uso y la política de tratamiento '
          'de datos antes del lanzamiento.',
      primaryLabel: 'Entendido',
      onPrimary: () => Navigator.pop(sheet),
      onClose: () => Navigator.pop(sheet),
    ),
  );
}
