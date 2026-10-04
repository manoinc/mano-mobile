import 'package:flutter/material.dart';

import '../../shell/module_placeholder.dart';

class MyServicesScreen extends StatelessWidget {
  const MyServicesScreen({super.key});

  @override
  Widget build(BuildContext context) => const ModulePlaceholder(
    title: 'Servicios',
    detail: 'PROV-02 · Mis servicios y ofertas',
  );
}
