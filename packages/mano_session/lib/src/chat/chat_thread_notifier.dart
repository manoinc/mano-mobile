import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../conversation_providers.dart';
import '../marketplace_providers.dart';
import '../media/photo_attachments_notifier.dart';
import 'chat_thread_item.dart';
import 'photo_caption.dart';

/// One conversation's live thread: history, incoming messages and my outgoing ones.
final chatThreadProvider = AsyncNotifierProvider.autoDispose
    .family<ChatThreadNotifier, List<ChatThreadItem>, String>(
      ChatThreadNotifier.new,
      // The screen offers its own retry; silent retries would hide the error.
      retry: (_, _) => null,
    );

final class ChatThreadNotifier extends AsyncNotifier<List<ChatThreadItem>> {
  ChatThreadNotifier(this.conversationId);

  final String conversationId;

  final List<Message> _confirmed = [];
  final List<OutgoingChatItem> _outgoing = [];
  var _nextLocalId = 0;

  ChatRepository get _repository => ref.read(chatRepositoryProvider);

  @override
  Future<List<ChatThreadItem>> build() async {
    final repository = ref.watch(chatRepositoryProvider);
    _confirmed.clear();
    _outgoing.clear();
    // Subscribe before loading so nothing slips between history and live.
    final subscription = repository.watch(conversationId).listen(_receive);
    ref.onDispose(subscription.cancel);

    final history = await repository.messages(conversationId);
    final live = List.of(_confirmed);
    _confirmed
      ..clear()
      ..addAll(history);
    live.forEach(_addConfirmed);
    unawaited(_markRead(repository));
    return _items();
  }

  /// Sends [text] with the composer's photos; waits while any is not uploaded.
  Future<void> send(String text) async {
    final attachments = photoAttachmentsProvider(ChatUpload(conversationId));
    final photos = ref.read(attachments);
    if (!ref.read(attachments.notifier).isReady) return;
    final typed = text.trim();
    if (typed.isEmpty && photos.isEmpty) return;
    final item = OutgoingChatItem(
      localId: 'local-${_nextLocalId++}',
      body: outgoingBody(typed, hasPhotos: photos.isNotEmpty),
      sentAt: DateTime.now(),
      photos: photos,
    );
    if (photos.isNotEmpty) ref.read(attachments.notifier).clear();
    _outgoing.add(item);
    _emit();
    await _deliver(item);
  }

  Future<void> retry(String localId) async {
    final index = _outgoing.indexWhere((item) => item.localId == localId);
    if (index < 0 || !_outgoing[index].failed) return;
    final item = _outgoing[index].copyWith(failed: false);
    _outgoing[index] = item;
    _emit();
    await _deliver(item);
  }

  Future<void> _deliver(OutgoingChatItem item) async {
    final result = await _repository.send(
      conversationId,
      item.body,
      mediaIds: item.mediaIds,
    );
    if (!ref.mounted) return;
    final index = _outgoing.indexWhere((o) => o.localId == item.localId);
    if (index < 0) return;
    switch (result) {
      case Ok(:final value):
        _outgoing.removeAt(index);
        _addConfirmed(value);
        ref.invalidate(conversationsProvider);
      case Err():
        _outgoing[index] = item.copyWith(failed: true);
    }
    _emit();
  }

  Future<void> _markRead(ChatRepository repository) async {
    final result = await repository.markRead(conversationId);
    if (ref.mounted && result.isOk) ref.invalidate(conversationsProvider);
  }

  void _receive(Message message) {
    final isNew = _addConfirmed(message);
    if (state.hasValue) _emit();
    // A new message changes the inbox; a status update does not.
    if (isNew && ref.mounted) ref.invalidate(conversationsProvider);
  }

  /// Adds or updates by id, never moving a status backwards; true when new.
  bool _addConfirmed(Message message) {
    final index = _confirmed.indexWhere((m) => m.id == message.id);
    if (index < 0) {
      _confirmed.add(message);
      return true;
    }
    if (message.status.index > _confirmed[index].status.index) {
      _confirmed[index] = message;
    }
    return false;
  }

  void _emit() => state = AsyncData(_items());

  List<ChatThreadItem> _items() => [
    for (final message in _confirmed) ConfirmedChatItem(message),
    ..._outgoing,
  ];
}
