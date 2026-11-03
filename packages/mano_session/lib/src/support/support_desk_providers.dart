import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

// Mock: the gateway's createSupportTicket is a stub. Shared by both apps.
final supportDeskProvider = Provider<SupportDesk>((ref) => MockSupportDesk());

/// Files a support ticket; the screen keeps the radicado it gets back.
final class SupportDeskActions extends Notifier<void> {
  @override
  void build() {}

  Future<Result<SupportTicket, DataFailure>> file(SupportTicketDraft draft) =>
      ref.read(supportDeskProvider).file(draft);
}

final supportDeskActionsProvider = NotifierProvider<SupportDeskActions, void>(
  SupportDeskActions.new,
);
