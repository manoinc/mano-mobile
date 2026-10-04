import 'package:flutter/material.dart';

import '../../shell/module_placeholder.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({required this.serviceId, super.key});

  final String serviceId;

  @override
  Widget build(BuildContext context) =>
      const ModulePlaceholder(title: 'Ofertas', detail: 'REQ-02 · Ofertas');
}
