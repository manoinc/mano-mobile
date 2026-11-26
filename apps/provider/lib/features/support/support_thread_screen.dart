import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// One support ticket: the description, then the replies, with a composer.
class SupportThreadScreen extends ConsumerWidget {
  const SupportThreadScreen({required this.ticketId, super.key});

  final String ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(myTicketsProvider);
    final thread = ref.watch(supportThreadProvider(ticketId));
    final ticket = tickets.value?.where((t) => t.id == ticketId).firstOrNull;

    Future<void> refresh() async {
      ref.invalidate(myTicketsProvider);
      ref.invalidate(supportThreadProvider(ticketId));
      await ref.read(supportThreadProvider(ticketId).future);
    }

    Future<bool> send(String body) async {
      final result = await ref.read(supportDeskProvider).send(ticketId, body);
      if (!context.mounted) return false;
      switch (result) {
        case Ok():
          ref.invalidate(supportThreadProvider(ticketId));
          return true;
        case Err(:final failure):
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(failure.message)));
          ref.invalidate(myTicketsProvider);
          return false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(ticket?.number ?? 'Solicitud'),
        actions: [
          if (ticket != null)
            Padding(
              padding: const EdgeInsets.only(right: ManoSpacing.md),
              child: ManoStatusChip(
                label: supportStatusLabel(ticket.status),
                tone: _tone(ticket.status),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: switch ((ticket, thread.value)) {
          (final ticket?, final messages?) => ManoSupportThread(
            entries: [
              ManoChatEntry(
                id: 'description',
                text: ticket.description,
                sentAt: ticket.createdAt,
                mine: true,
              ),
              for (final m in messages)
                ManoChatEntry(
                  id: m.id,
                  text: m.body,
                  sentAt: m.sentAt,
                  mine: !m.fromStaff,
                ),
            ],
            staffLabel: supportStaffLabel,
            hintText: 'Escribe un mensaje',
            closedNote: supportClosedNote,
            onRefresh: refresh,
            onSend: ticket.status.acceptsMessages ? send : null,
          ),
          _ when thread.hasError || tickets.hasError => ManoEmptyState(
            icon: Icons.cloud_off_rounded,
            message: 'No se pudo cargar la solicitud.',
            ctaLabel: 'Reintentar',
            onCta: () {
              ref.invalidate(myTicketsProvider);
              ref.invalidate(supportThreadProvider(ticketId));
            },
          ),
          _ => const Center(child: ManoSkeletonList()),
        },
      ),
    );
  }
}

ManoStatusTone _tone(SupportTicketStatus status) => switch (status) {
  SupportTicketStatus.filed => ManoStatusTone.info,
  SupportTicketStatus.inProgress => ManoStatusTone.warning,
  SupportTicketStatus.resolved => ManoStatusTone.success,
  SupportTicketStatus.closed => ManoStatusTone.neutral,
};
