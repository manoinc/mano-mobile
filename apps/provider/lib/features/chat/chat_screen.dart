import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../account/account_gate.dart';
import '../identity/verification_gate.dart';
import '../media/photo_picking.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({required this.conversationId, super.key});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = chatThreadProvider(conversationId);
    final thread = ref.watch(provider);
    final attachments = photoAttachmentsProvider(ChatUpload(conversationId));
    final photos = ref.watch(attachments);
    final photosNotifier = ref.read(attachments.notifier);

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
                onSend: (body) => _send(context, ref, body),
                onAttach: () => requireVerified(
                  context,
                  ref,
                  reason: AccountReason.chat,
                  action: () => pickPhoto(context, photosNotifier),
                ),
                attachments: pickedPhotos(photos),
                onRemoveAttachment: photosNotifier.remove,
                onRetryAttachment: photosNotifier.retry,
                canSend: photosNotifier.isReady,
              ),
            ],
          ),
          AsyncError() => ManoEmptyState(
            icon: Icons.cloud_off_rounded,
            message: 'No se pudo cargar la conversación.',
            ctaLabel: 'Reintentar',
            onCta: () => ref.invalidate(provider),
          ),
          _ => const ManoSkeletonList(),
        },
      ),
    );
  }

  /// True once the message goes out; the gate may keep it, and the draft.
  Future<bool> _send(BuildContext context, WidgetRef ref, String body) async {
    var sent = false;
    await requireVerified(
      context,
      ref,
      reason: AccountReason.chat,
      action: () {
        sent = true;
        unawaited(
          ref.read(chatThreadProvider(conversationId).notifier).send(body),
        );
      },
    );
    return sent;
  }

  static ManoChatEntry _entry(ChatThreadItem item) => switch (item) {
    ConfirmedChatItem(:final message) => ManoChatEntry(
      id: message.id,
      text: item.caption,
      sentAt: message.sentAt,
      mine: message.fromMe,
      receipt: _receipt(message.status),
      photos: [for (final url in item.photoUrls) NetworkImage(url)],
    ),
    OutgoingChatItem() => ManoChatEntry(
      id: item.localId,
      text: item.caption,
      sentAt: item.sentAt,
      mine: true,
      status: item.failed
          ? ManoChatEntryStatus.failed
          : ManoChatEntryStatus.pending,
      photos: [for (final p in item.photos) MemoryImage(p.bytes)],
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
