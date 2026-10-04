import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'chat_thread_view.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({required this.conversationId, super.key});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = chatThreadProvider(conversationId);
    final thread = ref.watch(provider);

    return Scaffold(
      appBar: AppBar(title: _Header(conversationId: conversationId)),
      body: SafeArea(
        top: false,
        child: switch (thread) {
          AsyncData(:final value) => Column(
            children: [
              Expanded(
                child: value.isEmpty
                    ? const _EmptyThread()
                    : ChatThreadView(
                        items: value,
                        onRetry: ref.read(provider.notifier).retry,
                      ),
              ),
              ManoMessageComposer(
                hintText: 'Escribe un mensaje',
                onSend: ref.read(provider.notifier).send,
              ),
            ],
          ),
          AsyncError() => _LoadError(onRetry: () => ref.invalidate(provider)),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversation = ref
        .watch(conversationsProvider)
        .value
        ?.where((c) => c.id == conversationId)
        .firstOrNull;
    if (conversation == null) return const SizedBox.shrink();

    return Row(
      children: [
        ManoAvatar(
          photoUrl: conversation.participantPhotoUrl,
          size: 36,
          online: conversation.isOnline,
        ),
        const SizedBox(width: ManoSpacing.sm),
        Flexible(
          child: Text(
            conversation.participantName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (conversation.isVerified) ...[
          const SizedBox(width: ManoSpacing.xs),
          const Icon(Icons.verified, size: 16, color: ManoColors.clay),
        ],
      ],
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.chat_bubble_outline_rounded,
          size: 40,
          color: ManoColors.faint,
        ),
        const SizedBox(height: ManoSpacing.sm),
        Text(
          'Escribe el primer mensaje',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: ManoColors.muted),
        ),
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(ManoSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No se pudo cargar la conversación.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: ManoColors.muted),
          ),
          const SizedBox(height: ManoSpacing.sm),
          ManoQuietButton(label: 'Reintentar', onPressed: onRetry),
        ],
      ),
    ),
  );
}
