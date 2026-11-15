import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../features/activity/activity_list.dart';

const _labels = {
  ActivityBucket.pending: 'Pendientes',
  ActivityBucket.active: 'En curso',
  ActivityBucket.history: 'Historial',
};

/// The Actividad tab at `/projects`: one status filter over requests, jobs and projects alike.
class ProjectsTabScreen extends StatefulWidget {
  const ProjectsTabScreen({super.key});

  @override
  State<ProjectsTabScreen> createState() => _ProjectsTabScreenState();
}

class _ProjectsTabScreenState extends State<ProjectsTabScreen> {
  ActivityBucket _bucket = ActivityBucket.pending;

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
                labels: [for (final b in ActivityBucket.values) _labels[b]!],
                selectedIndex: _bucket.index,
                onSelected: (i) =>
                    setState(() => _bucket = ActivityBucket.values[i]),
              ),
              const SizedBox(height: ManoSpacing.md),
              Expanded(child: ActivityList(bucket: _bucket)),
            ],
          ),
        ),
      ),
    );
  }
}
