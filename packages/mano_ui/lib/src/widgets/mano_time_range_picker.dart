import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

String _hhmm(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutes % 60).toString().padLeft(2, '0')}';

/// Two wheels, "Desde" and "Hasta", in half-hour steps; fixed height, never a full-screen menu.
class ManoTimeRangePicker extends StatefulWidget {
  const ManoTimeRangePicker({
    required this.startMinutes,
    required this.endMinutes,
    required this.onChanged,
    this.labelFor,
    super.key,
  });

  static const double height = 180;
  static const double itemExtent = 40;
  static const int _step = 30;
  static const int _day = 24 * 60;

  /// Minutes after midnight.
  final int startMinutes;
  final int endMinutes;
  final void Function(int startMinutes, int endMinutes) onChanged;

  /// Formats a time of day; defaults to "08:00".
  final String Function(int minutes)? labelFor;

  @override
  State<ManoTimeRangePicker> createState() => _ManoTimeRangePickerState();
}

class _ManoTimeRangePickerState extends State<ManoTimeRangePicker> {
  // Start runs 00:00..23:30, end 00:30..24:00.
  late final _startController = FixedExtentScrollController(
    initialItem: widget.startMinutes ~/ ManoTimeRangePicker._step,
  );
  late final _endController = FixedExtentScrollController(
    initialItem: widget.endMinutes ~/ ManoTimeRangePicker._step - 1,
  );

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const step = ManoTimeRangePicker._step;
    const day = ManoTimeRangePicker._day;
    final label = widget.labelFor ?? _hhmm;

    return SizedBox(
      height: ManoTimeRangePicker.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The band the selected row rests in; sits under the label strip.
          const Positioned(
            left: 0,
            right: 0,
            bottom:
                (ManoTimeRangePicker.height -
                    _captionHeight -
                    ManoTimeRangePicker.itemExtent) /
                2,
            child: _SelectionBand(),
          ),
          Row(
            children: [
              Expanded(
                child: _Wheel(
                  wheelKey: const Key('mano-time-wheel-start'),
                  caption: 'Desde',
                  controller: _startController,
                  labels: [for (var m = 0; m < day; m += step) label(m)],
                  onSelected: (i) =>
                      widget.onChanged(i * step, widget.endMinutes),
                ),
              ),
              const SizedBox(width: ManoSpacing.md),
              Expanded(
                child: _Wheel(
                  wheelKey: const Key('mano-time-wheel-end'),
                  caption: 'Hasta',
                  controller: _endController,
                  labels: [for (var m = step; m <= day; m += step) label(m)],
                  onSelected: (i) =>
                      widget.onChanged(widget.startMinutes, (i + 1) * step),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const double _captionHeight = 24;

class _SelectionBand extends StatelessWidget {
  const _SelectionBand();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ManoTimeRangePicker.itemExtent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.palette.sand,
          borderRadius: BorderRadius.all(Radius.circular(ManoRadius.card)),
        ),
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.wheelKey,
    required this.caption,
    required this.controller,
    required this.labels,
    required this.onSelected,
  });

  final Key wheelKey;
  final String caption;
  final FixedExtentScrollController controller;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        SizedBox(
          height: _captionHeight,
          child: Text(
            caption,
            style: textTheme.labelMedium?.copyWith(
              color: context.palette.faint,
            ),
          ),
        ),
        Expanded(
          child: ListWheelScrollView.useDelegate(
            key: wheelKey,
            controller: controller,
            itemExtent: ManoTimeRangePicker.itemExtent,
            diameterRatio: 2.2,
            perspective: 0.003,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onSelected,
            childDelegate: ListWheelChildListDelegate(
              children: [
                for (final text in labels)
                  Center(child: Text(text, style: textTheme.titleMedium)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
