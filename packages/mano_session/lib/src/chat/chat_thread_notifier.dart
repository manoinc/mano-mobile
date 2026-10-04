import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../conversation_providers.dart';
import '../marketplace_providers.dart';
import 'chat_thread_item.dart';

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

  Future<void> send(String text) async {
    final body = text.trim();
    if (body.isEmpty) return;
    final item = OutgoingChatItem(
      localId: 'local-${_nextLocalId++}',
      body: body,
      sentAt: DateTime.now(),
    );
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
    final result = await _repository.send(conversationId, item.body);
    if (!ref.mounted) return;
    final index = _outgoing.indexWhere((o) => o.localId == item.localId);
    if (index < 0) return;
    switch (result) {
      case Ok(:final value):
        _outgoing.removeAt(index);
        _addConfirmed(value);
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
    _addConfirmed(message);
    if (state.hasValue) _emit();
  }

  void _addConfirmed(Message message) {
    if (_confirmed.any((m) => m.id == message.id)) return;
    _confirmed.add(message);
  }

  void _emit() => state = AsyncData(_items());

  List<ChatThreadItem> _items() => [
    for (final message in _confirmed) ConfirmedChatItem(message),
    ..._outgoing,
  ];
}
