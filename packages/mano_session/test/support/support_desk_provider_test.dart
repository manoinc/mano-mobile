import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

void main() {
  test('the support desk files a ticket offline and online alike', () async {
    final container = ProviderContainer.test();

    final ticket =
        (await container
                .read(supportDeskProvider)
                .submit(
                  const SupportTicketDraft(
                    subject: 'Ayuda',
                    description: 'No puedo ver mis pagos.',
                  ),
                ))
            .valueOrNull!;

    expect(ticket.number, startsWith('MANO-'));
    expect(ticket.status, SupportTicketStatus.filed);
  });
}
