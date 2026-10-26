import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Bandeja: conversations with clients, newest activity first.
class ProviderInboxScreen extends ConsumerWidget {
  const ProviderInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ManoSpacing.md,
                ManoSpacing.md,
                ManoSpacing.md,
                ManoSpacing.sm,
              ),
              child: Text(
                'Mensajes',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Expanded(
              child: switch (conversations) {
                AsyncData(:final value) => ManoRefreshList(
                  onRefresh: () => ref.refresh(conversationsProvider.future),
                  emptyMessage: 'Aún no tienes conversaciones con clientes',
                  children: [
                    for (final conversation in value)
                      ManoConversationTile(
                        key: ValueKey(conversation.id),
                        avatarUrl: conversation.participantPhotoUrl,
                        online: conversation.isOnline,
                        verified: conversation.isVerified,
                        name: conversation.participantLabel,
                        snippet: conversation.preview,
                        timestampLabel: switch (conversation.lastMessageAt) {
                          final at? => ManoFormat.relative(at, DateTime.now()),
                          null => '',
                        },
                        unreadCount: conversation.unreadCount,
                        onTap: () => context.push('/inbox/${conversation.id}'),
                      ),
                  ],
                ),
                AsyncError() => ManoEmptyState(
                  icon: Icons.cloud_off_rounded,
                  message: 'No se pudo cargar tu bandeja.',
                  ctaLabel: 'Reintentar',
                  onCta: () => ref.invalidate(conversationsProvider),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
    );
  }
}
