import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../features/projects/account_gate.dart';

/// One Perfil row: where it goes, and whether a guest must sign in first.
typedef _MenuEntry = ({
  IconData icon,
  String label,
  String path,
  bool needsAccount,
});

const _menu = <_MenuEntry>[
  (
    icon: Icons.person_outline,
    label: 'Información personal',
    path: '/profile/personal',
    needsAccount: true,
  ),
  (
    icon: Icons.location_on_outlined,
    label: 'Direcciones guardadas',
    path: '/profile/addresses',
    needsAccount: false,
  ),
  (
    icon: Icons.payment_outlined,
    label: 'Métodos de pago',
    path: '/profile/payments',
    needsAccount: true,
  ),
  (
    icon: Icons.history,
    label: 'Historial de pedidos',
    path: '/profile/history',
    needsAccount: true,
  ),
  (
    icon: Icons.support_agent_outlined,
    label: 'Atención al cliente',
    path: '/profile/support',
    needsAccount: false,
  ),
  (
    icon: Icons.settings_outlined,
    label: 'Configuración',
    path: '/profile/settings',
    needsAccount: false,
  ),
];

const _accountMessage = 'Crea tu cuenta para guardar tus datos y tus pedidos.';

/// The Perfil tab: the user's header, the account menu, and the way out (or in).
class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final signedIn = ref.watch(hasAccountProvider);
    final profile = signedIn ? ref.watch(clientProfileProvider).value : null;
    final name = (profile?.displayName.isNotEmpty ?? false)
        ? profile!.displayName
        : user?.displayName ?? 'Solicitante';
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );

    void open(_MenuEntry entry) {
      if (entry.needsAccount &&
          !requireAccount(context, ref, _accountMessage)) {
        return;
      }
      context.push(entry.path);
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ManoSpacing.lg),
          children: [
            ManoProfileHeader(
              name: name,
              photoUrl: profile?.photoUrl,
              onEdit: () => open(_menu.first),
            ),
            const SizedBox(height: ManoSpacing.lg),
            for (final entry in _menu) ...[
              ManoOptionRow(
                icon: entry.icon,
                label: entry.label,
                onPressed: () => open(entry),
              ),
              divider,
            ],
            ManoOptionRow(
              icon: signedIn ? Icons.logout : Icons.login,
              label: signedIn ? 'Cerrar sesión' : 'Iniciar sesión',
              destructive: signedIn,
              onPressed: signedIn
                  ? () => ref.read(sessionProvider.notifier).signOut()
                  : () =>
                        ref.read(onboardingFlowProvider.notifier).startSignIn(),
            ),
          ],
        ),
      ),
    );
  }
}
