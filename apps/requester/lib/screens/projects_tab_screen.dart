import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Filter tab labels, in the exact order the tabs render.
const _filterLabels = [
  'Todos',
  'Programados',
  'En curso',
  'Completados',
  'Cancelados',
];

/// Maps a filter tab index to the `ProjectStatus` it restricts the list to.
/// Index 0 ("Todos") has no status, so it shows everything.
ProjectStatus? _statusFor(int filterIndex) => switch (filterIndex) {
  1 => ProjectStatus.scheduled,
  2 => ProjectStatus.inProgress,
  3 => ProjectStatus.completed,
  4 => ProjectStatus.canceled,
  _ => null,
};

/// A domain `ProjectStatus` read as a badge: pre-formatted label and the
/// tone `ManoProjectCard` renders it in.
(String, ManoStatusTone) _badgeFor(ProjectStatus status) => switch (status) {
  ProjectStatus.scheduled => ('Programado', ManoStatusTone.info),
  ProjectStatus.inProgress => ('En curso', ManoStatusTone.warning),
  ProjectStatus.completed => ('Completado', ManoStatusTone.success),
  ProjectStatus.canceled => ('Cancelado', ManoStatusTone.neutral),
};

const _monthAbbreviations = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// Turns a `DateTime` into "12 mar, 3:00 p. m.": day, Spanish month
/// abbreviation, and 12-hour time. No `intl` dependency in this app, so this
/// stays a small, screen-local helper rather than pulling one in.
String _scheduledLabel(DateTime dateTime) {
  final month = _monthAbbreviations[dateTime.month - 1];
  final hour12 = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final suffix = dateTime.hour < 12 ? 'a. m.' : 'p. m.';
  return '${dateTime.day} $month, $hour12:$minute $suffix';
}

/// Turns cents into "$80.000 COP": Colombian pesos, thousands separated by
/// dots. Duplicated from the Home tab's equivalent helper on purpose -- two
/// small private helpers is simpler than a shared utility file for this.
String _copLabel(int priceCents) {
  final pesos = priceCents ~/ 100;
  final digits = pesos.toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write('.');
    grouped.write(digits[i]);
  }
  return '\$$grouped COP';
}

void _showStub(BuildContext context) {
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Muy pronto')));
}

/// The Proyectos tab: a row of status filter tabs over a list of the
/// requester's projects, or one generic empty state when the filtered list
/// has nothing to show.
///
/// Nothing here has a real destination yet -- no project-detail screen --
/// so tapping a card shows the stub notice instead of a silent no-op.
class ProjectsTabScreen extends ConsumerStatefulWidget {
  const ProjectsTabScreen({super.key});

  @override
  ConsumerState<ProjectsTabScreen> createState() => _ProjectsTabScreenState();
}

class _ProjectsTabScreenState extends ConsumerState<ProjectsTabScreen> {
  int _selectedFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ManoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ManoProjectFilterTabs(
                labels: _filterLabels,
                selectedIndex: _selectedFilterIndex,
                onSelected: (index) =>
                    setState(() => _selectedFilterIndex = index),
              ),
              const SizedBox(height: ManoSpacing.md),
              Expanded(
                child: projects.when(
                  data: (items) {
                    final status = _statusFor(_selectedFilterIndex);
                    final filtered = status == null
                        ? items
                        : items
                              .where((project) => project.status == status)
                              .toList();
                    return _ProjectList(
                      allProjects: items,
                      filteredProjects: filtered,
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) =>
                      const Center(child: Text('No se pudo cargar.')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders the filtered project list, or an empty state when it's empty --
/// distinguishing *why* it's empty, because the two cases say different
/// things:
///
/// - The user genuinely has zero projects: the "you haven't requested any
///   service yet" copy, with the "request your first service" CTA.
/// - The user has projects, but none match the selected filter (e.g. no
///   canceled jobs): a filter-specific message with no CTA, since offering
///   to "request your first service" would be nonsensical for someone who
///   plainly already has.
class _ProjectList extends StatelessWidget {
  const _ProjectList({required this.allProjects, required this.filteredProjects});

  final List<Project> allProjects;
  final List<Project> filteredProjects;

  @override
  Widget build(BuildContext context) {
    if (allProjects.isEmpty) {
      return ManoEmptyState(
        icon: Icons.pan_tool_outlined,
        message: 'Aún no has solicitado ningún servicio',
        ctaLabel: 'Solicita tu primer servicio',
        onCta: () => _showStub(context),
      );
    }

    if (filteredProjects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(ManoSpacing.lg),
          child: Text(
            'No hay proyectos en esta categoría.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredProjects.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: ManoSpacing.sm),
      itemBuilder: (context, index) {
        final project = filteredProjects[index];
        final (statusLabel, statusTone) = _badgeFor(project.status);
        return ManoProjectCard(
          title: project.title,
          professionalName: project.professionalName,
          professionalPhotoUrl: project.professionalPhotoUrl,
          statusLabel: statusLabel,
          statusTone: statusTone,
          scheduledLabel: _scheduledLabel(project.scheduledAt),
          priceLabel: _copLabel(project.priceCents),
          onTap: () => _showStub(context),
        );
      },
    );
  }
}
