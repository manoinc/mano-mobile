import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

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
                child: ManoChatThread(
                  entries: value.map(_entry).toList(),
                  emptyMessage: 'Escribe el primer mensaje',
                  onRetry: ref.read(provider.notifier).retry,
                ),
              ),
              ManoMessageComposer(
                hintText: 'Escribe un mensaje',
                onSend: ref.read(provider.notifier).send,
              ),
            ],
          ),
          AsyncError() => ManoEmptyState(
            icon: Icons.cloud_off_rounded,
            message: 'No se pudo cargar la conversación.',
            ctaLabel: 'Reintentar',
            onCta: () => ref.invalidate(provider),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  static ManoChatEntry _entry(ChatThreadItem item) => switch (item) {
    ConfirmedChatItem(:final message) => ManoChatEntry(
      id: message.id,
      text: message.body,
      sentAt: message.sentAt,
      mine: message.fromMe,
      receipt: _receipt(message.status),
    ),
    OutgoingChatItem() => ManoChatEntry(
      id: item.localId,
      text: item.body,
      sentAt: item.sentAt,
      mine: true,
      status: item.failed
          ? ManoChatEntryStatus.failed
          : ManoChatEntryStatus.pending,
    ),
  };
}

ManoReceipt _receipt(MessageStatus status) => switch (status) {
  MessageStatus.sent => ManoReceipt.sent,
  MessageStatus.delivered => ManoReceipt.delivered,
  MessageStatus.read => ManoReceipt.read,
};

String _roleLabel(String role) =>
    role == ManoRole.provider ? 'Profesional' : 'Cliente';

class _Header extends ConsumerWidget {
  const _Header({required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversation = ref.watch(conversationProvider(conversationId));
    if (conversation == null) return const SizedBox.shrink();

    return ManoChatHeader(
      name: conversation.participantLabel,
      photoUrl: conversation.participantPhotoUrl,
      online: conversation.isOnline,
      verified: conversation.isVerified,
      onTap: () => showManoSheet<void>(
        context: context,
        builder: (sheet) => ManoProfileSheet(
          name: conversation.participantLabel,
          photoUrl: conversation.participantPhotoUrl,
          verified: conversation.isVerified,
          facts: [
            ManoProfileFact(
              label: 'Rol',
              value: _roleLabel(conversation.participantRole),
            ),
            ManoProfileFact(
              label: 'Estado',
              value: conversation.isOnline ? 'En línea' : 'Desconectado',
            ),
          ],
          actionLabel: 'Cerrar',
          onAction: () => Navigator.of(sheet).pop(),
        ),
      ),
    );
  }
}
