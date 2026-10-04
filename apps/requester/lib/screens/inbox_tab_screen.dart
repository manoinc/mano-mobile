import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Turns a message timestamp into a short relative label: "5m", "3h", "2d".
/// Always at least 1 of whichever unit applies -- a message from 30 seconds
/// ago reads "1m", not "0m". Kept as a tiny self-contained helper rather
/// than a package dependency, since the format needed here is this narrow.
String _relativeLabel(DateTime lastMessageAt, DateTime now) {
  final elapsed = now.difference(lastMessageAt);
  if (elapsed.inHours < 1) {
    return '${elapsed.inMinutes < 1 ? 1 : elapsed.inMinutes}m';
  }
  if (elapsed.inHours < 24) {
    return '${elapsed.inHours}h';
  }
  return '${elapsed.inDays < 1 ? 1 : elapsed.inDays}d';
}

/// The Bandeja tab: a plain list of conversations, newest activity first as
/// the repository already orders them. Tapping a tile opens its chat.
class InboxTabScreen extends ConsumerWidget {
  const InboxTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      body: SafeArea(
        child: conversations.when(
          data: (items) => RefreshIndicator(
            onRefresh: () => ref.refresh(conversationsProvider.future),
            child: _list(context, items),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              const Center(child: Text('No se pudo cargar.')),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<Conversation> items) {
    // Always scrollable, so even an empty or short list can be pulled.
    const physics = AlwaysScrollableScrollPhysics();
    if (items.isEmpty) {
      return ListView(
        physics: physics,
        children: const [
          SizedBox(height: ManoSpacing.xl * 4),
          Center(child: Text('Aún no tienes conversaciones.')),
        ],
      );
    }
    final now = DateTime.now();
    return ListView.separated(
      physics: physics,
      itemCount: items.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      itemBuilder: (context, index) {
        final conversation = items[index];
        return ManoConversationTile(
          avatarUrl: conversation.participantPhotoUrl,
          online: conversation.isOnline,
          verified: conversation.isVerified,
          name: conversation.participantName,
          snippet: conversation.lastMessage,
          timestampLabel: _relativeLabel(conversation.lastMessageAt, now),
          unreadCount: conversation.unreadCount,
          onTap: () => context.push('/inbox/${conversation.id}'),
        );
      },
    );
  }
}
