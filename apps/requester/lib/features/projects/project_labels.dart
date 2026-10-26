import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

// Domain → copy for the Proyectos screens; mano_ui cannot see these types.

/// Where a project stands, for its card: the chip and what sits beside it.
({String label, ManoStatusTone tone, String? trailing}) projectStatusLine(
  Project project,
) {
  final live = project.liveQuotes;
  final picked = project.selectedQuote;
  return switch (project.status) {
    ProjectStatus.open when live.isEmpty => (
      label: 'Esperando cotizaciones',
      tone: ManoStatusTone.neutral,
      trailing: null,
    ),
    ProjectStatus.open => (
      label: live.length == 1 ? '1 cotización' : '${live.length} cotizaciones',
      tone: ManoStatusTone.info,
      trailing: 'desde ${ManoFormat.cop(project.lowestQuoteCop!)}',
    ),
    ProjectStatus.awarded => (
      label: 'Elegiste a ${picked?.workerName ?? 'Profesional'}',
      tone: ManoStatusTone.success,
      trailing: picked == null ? null : ManoFormat.cop(picked.amountCop),
    ),
    ProjectStatus.closed => (
      label: 'Cerrado',
      tone: ManoStatusTone.neutral,
      trailing: null,
    ),
    ProjectStatus.cancelled => (
      label: 'Cancelado',
      tone: ManoStatusTone.neutral,
      trailing: null,
    ),
  };
}

/// "Pintura · hace 5h"
String projectSubtitle(Project project, DateTime now) =>
    '${ServiceCategories.labelOf(project.category)} · '
    '${ManoFormat.ago(project.createdAt, now)}';

String budgetLabel(int? budgetCop) =>
    budgetCop == null ? 'Sin presupuesto' : ManoFormat.cop(budgetCop);
