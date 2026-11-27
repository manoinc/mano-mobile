import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'agenda_labels.dart';

/// Asks how long an hourly job took; pops the hours, or null if dismissed.
class HourLoggerSheet extends StatefulWidget {
  const HourLoggerSheet({
    required this.initialHours,
    required this.rateCop,
    super.key,
  });

  final double initialHours;
  final int rateCop;

  @override
  State<HourLoggerSheet> createState() => _HourLoggerSheetState();
}

class _HourLoggerSheetState extends State<HourLoggerSheet> {
  late double _hours = widget.initialHours;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ManoPromptSheet(
      title: '¿Cuántas horas trabajaste?',
      message: 'Ajusta el tiempo en medias horas antes de finalizar.',
      primaryLabel: 'Confirmar',
      onPrimary: () => Navigator.of(context).pop(_hours),
      onClose: () => Navigator.of(context).pop(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const Key('hour-logger-minus'),
                icon: const Icon(Icons.remove),
                onPressed: canRemoveHalfHour(_hours)
                    ? () => setState(() => _hours = removeHalfHour(_hours))
                    : null,
              ),
              SizedBox(
                width: 96,
                child: Text(
                  hoursLabel(_hours),
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall,
                ),
              ),
              IconButton(
                key: const Key('hour-logger-plus'),
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => _hours = addHalfHour(_hours)),
              ),
            ],
          ),
          const SizedBox(height: ManoSpacing.xs),
          Text(
            'Total ${ManoFormat.cop(hourlyTotalCop(_hours, widget.rateCop))}',
            style: textTheme.bodyLarge?.copyWith(color: context.palette.muted),
          ),
        ],
      ),
    );
  }
}
