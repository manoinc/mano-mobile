import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'account_gate.dart';

/// Opens the publish flow, with [category] preselected; guests are asked to sign in.
void startPublishing(BuildContext context, WidgetRef ref, {String? category}) {
  if (!requireAccount(
    context,
    ref,
    'Inicia sesión para publicar tu proyecto y recibir cotizaciones.',
  )) {
    return;
  }
  context.push(category == null ? '/publish' : '/publish?category=$category');
}
