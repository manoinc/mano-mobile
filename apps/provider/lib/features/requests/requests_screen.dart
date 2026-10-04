import 'package:flutter/material.dart';

import '../../shell/module_placeholder.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) => const ModulePlaceholder(
    title: 'Solicitudes',
    detail: 'PROV-04 · Solicitudes entrantes',
  );
}
