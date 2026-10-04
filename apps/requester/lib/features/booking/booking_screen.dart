import 'package:flutter/material.dart';

import '../../shell/module_placeholder.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({required this.offerId, super.key});

  final String offerId;

  @override
  Widget build(BuildContext context) =>
      const ModulePlaceholder(title: 'Agendar', detail: 'REQ-03 · Agendar');
}
