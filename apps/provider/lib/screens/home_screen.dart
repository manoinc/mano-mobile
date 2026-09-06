import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// What a signed-in Proveedor sees.
///
/// A placeholder, and honestly labelled as one. The service catalogue lives
/// behind `jobservicecrud`, which the gateway cannot yet reach, so there is no
/// real data to render and guessing at its shape would only create screens to
/// throw away.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({required this.session, super.key});

  final Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = session.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mano Pro'),
        actions: [
          IconButton(
            onPressed: () => ref.read(sessionProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ManoSpacing.md),
          children: [
            Text(
              'Hola, ${user.displayName}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: ManoSpacing.lg),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(ManoSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verificado por el backend',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: ManoSpacing.xs),
                    Text(
                      'mano-gateway comprobó la firma, el emisor, la audiencia '
                      'y la expiración antes de devolver esta identidad.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Divider(height: ManoSpacing.lg),
                    ManoDetailRow(
                      label: 'subject',
                      value: user.subject,
                      monospace: true,
                    ),
                    ManoDetailRow(
                      label: 'username',
                      value: user.username ?? '—',
                    ),
                    ManoDetailRow(label: 'email', value: user.email ?? '—'),
                    const SizedBox(height: ManoSpacing.sm),
                    ManoTagList(
                      tags: user.roles.toList()..sort(),
                      emptyLabel: 'Sin roles asignados',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: ManoSpacing.md),

            if (!user.isProvider)
              const ManoNotice(
                message:
                    'Esta cuenta no tiene el rol de proveedor. Podrás '
                    'iniciar sesión, pero no recibir trabajos.',
                tone: ManoNoticeTone.warning,
              ),
          ],
        ),
      ),
    );
  }
}
