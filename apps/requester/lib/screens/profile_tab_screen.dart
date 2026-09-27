import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

void _showStub(BuildContext context) {
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Muy pronto')));
}

/// One row of the Profile menu that has no real destination yet -- tapping
/// it just shows the stub notice. "Cerrar sesión" is the one exception, and
/// is appended separately in the build method because it needs `ref`.
typedef _StubMenuEntry = ({IconData icon, String label});

const _stubMenuEntries = <_StubMenuEntry>[
  (icon: Icons.person_outline, label: 'Información personal'),
  (icon: Icons.location_on_outlined, label: 'Direcciones guardadas'),
  (icon: Icons.payment_outlined, label: 'Métodos de pago'),
  (icon: Icons.history, label: 'Historial de pedidos'),
  (icon: Icons.support_agent_outlined, label: 'Atención al cliente'),
  (icon: Icons.settings_outlined, label: 'Configuración'),
];

/// The Perfil tab: the signed-in user's header plus a grouped menu list.
///
/// Every row is a stub notice except "Cerrar sesión", which is the one real
/// action here -- it tells [sessionProvider] to sign out, same as the old
/// placeholder AppBar button this replaces.
class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: theme.colorScheme.outlineVariant,
    );

    // AuthenticatedUser has no photo-URL field yet -- a real one belongs
    // here once the backend provides it, added in its own task. Until then
    // this passes no photo at all: inventing one (e.g. from `user.subject`)
    // would leak the real signed-in user's identifier to a third party and
    // show them a stranger's face as their own. `ManoProfileHeader` and
    // `ManoAvatar` render their stone-circle fallback for `null`.
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ManoSpacing.lg),
          children: [
            ManoProfileHeader(
              name: user?.displayName ?? 'Solicitante',
              photoUrl: null,
              onEdit: () => _showStub(context),
            ),
            const SizedBox(height: ManoSpacing.lg),
            for (final entry in _stubMenuEntries) ...[
              ManoOptionRow(
                icon: entry.icon,
                label: entry.label,
                onPressed: () => _showStub(context),
              ),
              divider,
            ],
            ManoOptionRow(
              icon: Icons.logout,
              label: 'Cerrar sesión',
              destructive: true,
              onPressed: () => ref.read(sessionProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
