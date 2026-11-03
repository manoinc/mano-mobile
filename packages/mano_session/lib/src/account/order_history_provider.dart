import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../marketplace_providers.dart';

const _closed = {JobStatus.finished, JobStatus.cancelled};

/// Finished and cancelled jobs, newest first: Perfil's Historial de pedidos.
final orderHistoryProvider = FutureProvider<List<Job>>((ref) async {
  final jobs = await ref.watch(myJobsProvider.future);
  return [
    for (final job in jobs)
      if (_closed.contains(job.status)) job,
  ]..sort((a, b) => b.start.compareTo(a.start));
});
