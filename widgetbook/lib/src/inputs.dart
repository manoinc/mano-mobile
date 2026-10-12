import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'sample.dart';

const _categories = [
  ManoCategoryRailItem(id: 'cleaning', icon: Icons.cleaning_services_outlined, label: 'Limpieza'),
  ManoCategoryRailItem(id: 'plumbing', icon: Icons.plumbing, label: 'Plomería'),
  ManoCategoryRailItem(id: 'electrical', icon: Icons.electrical_services, label: 'Electricidad'),
  ManoCategoryRailItem(id: 'painting', icon: Icons.format_paint_outlined, label: 'Pintura'),
];

WidgetbookCategory inputs() => WidgetbookCategory(
  name: 'Inputs',
  children: [
    component('ManoTextField', {
      'Default': (context) => _padded(
        ManoTextField(
          label: context.knobs.string(label: 'Label', initialValue: 'Nombre para mostrar'),
          controller: TextEditingController(),
          helperText: context.knobs.stringOrNull(label: 'Helper', initialValue: 'Así te verán los clientes.'),
          errorText: context.knobs.stringOrNull(label: 'Error'),
          enabled: context.knobs.boolean(label: 'Enabled', initialValue: true),
        ),
      ),
      'Multiline': (context) => _padded(
        ManoTextField(
          label: 'Mensaje',
          controller: TextEditingController(text: '¿Podrías venir el sábado en la mañana?'),
          minLines: 3,
          maxLines: 5,
        ),
      ),
    }),
    component('ManoSearchField', {
      'Default': (context) => _padded(ManoSearchField(controller: TextEditingController())),
    }),
    component('ManoSearchPill', {
      'Default': (context) => _padded(ManoSearchPill(onTap: noop)),
    }),
    component('ManoAddressPill', {
      'Default': (context) => _padded(
        ManoAddressPill(
          address: context.knobs.string(label: 'Address', initialValue: 'Agrega tu dirección'),
          onTap: noop,
        ),
      ),
    }),
    component('ManoToggleRow', {
      'Default': (context) => _padded(
        ManoToggleRow(
          label: 'Notificaciones',
          value: context.knobs.boolean(label: 'Value', initialValue: true),
          onChanged: (_) {},
        ),
      ),
    }),
    component('ManoCategoryChip', {
      'Default': (context) => Center(
        child: ManoCategoryChip(
          icon: Icons.plumbing,
          label: 'Plomería',
          selected: context.knobs.boolean(label: 'Selected'),
          onTap: noop,
        ),
      ),
    }),
    component('ManoCategoryRail', {
      'Default': (context) => _padded(
        ManoCategoryRail(
          items: _categories,
          selectedId: switch (context.knobs.object.dropdown<String>(
            label: 'Selected',
            options: ['none', for (final c in _categories) c.id],
          )) {
            'none' => null,
            final id => id,
          },
          onSelected: (_) {},
        ),
      ),
    }),
    component('ManoProjectFilterTabs', {
      'Default': (context) => _padded(
        ManoProjectFilterTabs(
          labels: const ['Todas', 'Precio fijo', 'Por hora'],
          selectedIndex: context.knobs.int.slider(label: 'Selected', initialValue: 0, min: 0, max: 2),
          onSelected: (_) {},
        ),
      ),
    }),
    component('ManoWeekdayPicker', {
      'Default': (context) => _padded(
        ManoWeekdayPicker(
          selected: {
            for (var d = 1; d <= context.knobs.int.slider(label: 'Days', initialValue: 5, min: 0, max: 7); d++) d,
          },
          onToggle: (_) {},
        ),
      ),
    }),
    component('ManoDateStrip', {
      'Default': (context) {
        final today = DateTime(2026, 10, 5);
        final days = [for (var i = 0; i < 14; i++) today.add(Duration(days: i))];
        return _padded(
          ManoDateStrip(
            days: days,
            selected: days[context.knobs.int.slider(label: 'Selected day', initialValue: 1, min: 0, max: 13)],
            weekdayLabel: ManoFormat.weekdayShort,
            isEnabled: (d) => d.weekday != DateTime.sunday,
            onSelected: (_) {},
          ),
        );
      },
    }),
    component('ManoMonthCalendar', {
      'Default': (context) => _padded(
        _MonthCalendarDemo(
          withMarks: context.knobs.boolean(label: 'Days with events', initialValue: true),
        ),
      ),
    }),
    component('ManoTimeRangePicker', {
      'Default': (context) => _padded(_TimeRangeDemo()),
    }),
    component('ManoSlotGrid', {
      'Default': (context) => _padded(
        ManoSlotGrid(
          slots: const [
            ManoSlot(label: '8:00 a. m.'),
            ManoSlot(label: '9:00 a. m.'),
            ManoSlot(label: '10:00 a. m.', enabled: false),
            ManoSlot(label: '11:00 a. m.'),
            ManoSlot(label: '2:00 p. m.', enabled: false),
            ManoSlot(label: '3:00 p. m.'),
          ],
          selectedIndex: context.knobs.intOrNull.slider(label: 'Selected', initialValue: 1, min: 0, max: 5),
          onSelected: (_) {},
        ),
      ),
      'Empty': (context) => _padded(
        ManoSlotGrid(slots: const [], selectedIndex: null, onSelected: (_) {}, emptyLabel: 'No hay horarios este día.'),
      ),
    }),
    component('ManoMessageComposer', {
      'Default': (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ManoMessageComposer(hintText: 'Escribe un mensaje', onSend: (_) {}),
      ),
    }),
  ],
);

class _MonthCalendarDemo extends StatefulWidget {
  const _MonthCalendarDemo({required this.withMarks});

  final bool withMarks;

  @override
  State<_MonthCalendarDemo> createState() => _MonthCalendarDemoState();
}

class _MonthCalendarDemoState extends State<_MonthCalendarDemo> {
  DateTime _month = DateTime(2026, 10);
  DateTime _selected = DateTime(2026, 10, 15);

  @override
  Widget build(BuildContext context) => ManoMonthCalendar(
    month: _month,
    selected: _selected,
    markedDays: widget.withMarks
        ? {DateTime(2026, 10, 7), DateTime(2026, 10, 15), DateTime(2026, 10, 22)}
        : const {},
    onSelect: (d) => setState(() => _selected = d),
    onMonthChanged: (m) => setState(() => _month = m),
  );
}

class _TimeRangeDemo extends StatefulWidget {
  @override
  State<_TimeRangeDemo> createState() => _TimeRangeDemoState();
}

class _TimeRangeDemoState extends State<_TimeRangeDemo> {
  int _start = 8 * 60;
  int _end = 12 * 60;

  @override
  Widget build(BuildContext context) => ManoTimeRangePicker(
    startMinutes: _start,
    endMinutes: _end,
    onChanged: (s, e) => setState(() {
      _start = s;
      _end = e;
    }),
  );
}

Widget _padded(Widget child) =>
    Center(child: Padding(padding: const EdgeInsets.all(ManoSpacing.lg), child: child));
