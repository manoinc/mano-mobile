import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

import '../projects/my_quotes_section.dart';
import '../projects/open_projects_section.dart';
import 'requests_section.dart';

enum _Segment { requests, projects, quotes }

/// Inicio's daily work: Solicitudes · Proyectos · Mis cotizaciones.
class HomeSegments extends StatefulWidget {
  const HomeSegments({super.key});

  @override
  State<HomeSegments> createState() => _HomeSegmentsState();
}

class _HomeSegmentsState extends State<HomeSegments> {
  _Segment _segment = _Segment.requests;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ManoProjectFilterTabs(
          labels: const ['Solicitudes', 'Proyectos', 'Mis cotizaciones'],
          selectedIndex: _segment.index,
          onSelected: (i) => setState(() => _segment = _Segment.values[i]),
        ),
        const SizedBox(height: ManoSpacing.md),
        switch (_segment) {
          _Segment.requests => const RequestsSection(),
          _Segment.projects => const OpenProjectsSection(),
          _Segment.quotes => MyQuotesSection(
            onBrowse: () => setState(() => _segment = _Segment.projects),
          ),
        },
      ],
    );
  }
}
