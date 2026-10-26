import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

import '../features/activity/activity_tab.dart';
import '../features/projects/my_projects_list.dart';

/// The Actividad tab at `/projects`: Servicios (`features/activity/`) or Proyectos (`features/projects/`).
class ProjectsTabScreen extends StatefulWidget {
  const ProjectsTabScreen({this.showProjects = false, super.key});

  /// Opens on the Proyectos segment, e.g. after publishing one.
  final bool showProjects;

  @override
  State<ProjectsTabScreen> createState() => _ProjectsTabScreenState();
}

class _ProjectsTabScreenState extends State<ProjectsTabScreen> {
  late bool _projects = widget.showProjects;

  @override
  void didUpdateWidget(ProjectsTabScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A link to the segment wins over the last choice.
    if (widget.showProjects && !oldWidget.showProjects) _projects = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ManoSpacing.md,
            ManoSpacing.md,
            ManoSpacing.md,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tu actividad',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: ManoSpacing.md),
              ManoProjectFilterTabs(
                labels: const ['Servicios', 'Proyectos'],
                selectedIndex: _projects ? 1 : 0,
                onSelected: (i) => setState(() => _projects = i == 1),
              ),
              const SizedBox(height: ManoSpacing.sm),
              Expanded(
                child: _projects ? const MyProjectsList() : const ActivityTab(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
