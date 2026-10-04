import 'package:flutter/material.dart';

import '../../shell/module_placeholder.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({this.category, super.key});

  final String? category;

  @override
  Widget build(BuildContext context) =>
      const ModulePlaceholder(title: 'Buscar', detail: 'REQ-01 · Explorar');
}
