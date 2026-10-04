import 'package:flutter/material.dart';

import '../../shell/module_placeholder.dart';

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) => const ModulePlaceholder(
    title: 'Agenda',
    detail: 'PROV-05 · Agenda de trabajos',
  );
}
