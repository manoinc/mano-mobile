import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Bandeja: conversations, newest activity first; a tile opens its chat.
class InboxTabScreen extends ConsumerWidget {
  const InboxTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      body: SafeArea(
        child: switch (conversations) {
          AsyncData(:final value) => ManoRefreshList(
            onRefresh: () => ref.refresh(conversationsProvider.future),
            emptyMessage: 'Aún no tienes conversaciones.',
            children: [
              for (final conversation in value)
                ManoConversationTile(
                  avatarUrl: conversation.participantPhotoUrl,
                  online: conversation.isOnline,
                  verified: conversation.isVerified,
                  name: conversation.participantName,
                  snippet: conversation.lastMessage,
                  timestampLabel: ManoFormat.relative(
                    conversation.lastMessageAt,
                    DateTime.now(),
                  ),
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
    );
  }
}
