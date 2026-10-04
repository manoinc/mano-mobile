import 'package:flutter/material.dart';

import '../../shell/module_placeholder.dart';

class AgendaJobScreen extends StatelessWidget {
  const AgendaJobScreen({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context) => const ModulePlaceholder(
    title: 'Trabajo',
    detail: 'PROV-05 · Detalle del trabajo',
  );
}
