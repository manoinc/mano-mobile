import 'package:flutter/material.dart';

import '../../shell/module_placeholder.dart';

class OfferEditorScreen extends StatelessWidget {
  const OfferEditorScreen({this.offerId, super.key});

  final String? offerId;

  @override
  Widget build(BuildContext context) => const ModulePlaceholder(
    title: 'Oferta',
    detail: 'PROV-02 · Editor de oferta',
  );
}
