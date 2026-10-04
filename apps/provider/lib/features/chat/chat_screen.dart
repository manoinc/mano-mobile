import 'package:flutter/material.dart';

import '../../shell/module_placeholder.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({required this.conversationId, super.key});

  final String conversationId;

  @override
  Widget build(BuildContext context) =>
      const ModulePlaceholder(title: 'Chat', detail: 'PROV-06 · Chat');
}
