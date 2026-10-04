import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// Stands in for a screen module until its workstream replaces it.
class ModulePlaceholder extends StatelessWidget {
  const ModulePlaceholder({
    required this.title,
    required this.detail,
    super.key,
  });

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(ManoSpacing.lg),
          child: Text(
            detail,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: ManoColors.faint),
          ),
        ),
      ),
    );
  }
}
