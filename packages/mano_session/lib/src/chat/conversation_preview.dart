import 'package:mano_domain/mano_domain.dart';

/// The inbox row's snippet: the last message, or that there is none yet.
extension ConversationPreview on Conversation {
  String get preview => lastMessage.isEmpty ? 'Sin mensajes aún' : lastMessage;
}
