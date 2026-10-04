import 'package:flutter/material.dart';

import '../features/activity/activity_tab.dart';

/// The Actividad tab at `/projects`; the implementation lives in `features/activity/`.
class ProjectsTabScreen extends StatelessWidget {
  const ProjectsTabScreen({super.key});

  @override
  Widget build(BuildContext context) => const ActivityTab();
}
