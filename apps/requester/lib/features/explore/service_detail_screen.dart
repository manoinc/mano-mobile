import 'package:flutter/material.dart';

import '../../shell/module_placeholder.dart';

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({required this.serviceId, super.key});

  final String serviceId;

  @override
  Widget build(BuildContext context) => const ModulePlaceholder(
    title: 'Servicio',
    detail: 'REQ-01 · Detalle del servicio',
  );
}
