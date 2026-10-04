import 'package:flutter/material.dart';

import '../../shell/module_placeholder.dart';

class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context) => const ModulePlaceholder(
    title: 'Trabajo',
    detail: 'REQ-04 · Detalle del trabajo',
  );
}
