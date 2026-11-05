import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// The requester's phone and email once the lead is bought, each one tap away.
class ClientContactSection extends ConsumerWidget {
  const ClientContactSection({required this.contact, super.key});

  final ContactInfo contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> open(Uri uri) async {
      final opened = await ref.read(externalLinkOpenerProvider)(uri);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos abrir esa app')),
        );
      }
    }

    final phone = contact.phone;
    final email = contact.email;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ManoSectionHeader(title: 'Contacto del cliente'),
        if (phone != null) ...[
          _row(
            Icons.call_outlined,
            phone,
            'Celular',
            'Llamar',
            () => open(phoneCallUri(phone)),
          ),
          _row(
            Icons.chat_bubble_outline,
            'WhatsApp',
            phone,
            'Abrir',
            () => open(whatsAppUri(phone)),
          ),
        ],
        if (email != null)
          _row(
            Icons.mail_outline,
            email,
            'Correo',
            'Escribir',
            () => open(emailUri(email)),
          ),
      ],
    );
  }

  Widget _row(
    IconData icon,
    String title,
    String status,
    String action,
    VoidCallback onAction,
  ) => Padding(
    padding: const EdgeInsets.only(top: ManoSpacing.md),
    child: ManoIntegrationRow(
      leading: Icon(icon, color: ManoColors.muted),
      title: title,
      status: status,
      actionLabel: action,
      onAction: onAction,
    ),
  );
}
