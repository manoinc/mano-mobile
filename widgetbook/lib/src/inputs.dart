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
    component('ManoPhoneField', {
      'Empty': (context) => _padded(
        ManoPhoneField(
          controller: TextEditingController(),
          helperText: 'Te enviaremos un código por SMS.',
          enabled: context.knobs.boolean(label: 'Enabled', initialValue: true),
        ),
      ),
      'Error': (context) => _padded(
        ManoPhoneField(
          controller: TextEditingController(text: '300 12'),
          helperText: 'Te enviaremos un código por SMS.',
          errorText: context.knobs.string(
            label: 'Error',
            initialValue: 'Escribe un celular colombiano: 10 dígitos que empiezan por 3.',
          ),
        ),
      ),
    }),
    component('ManoOtpField', {
      'Empty': (context) => _padded(const ManoOtpField(value: '')),
      'Typing': (context) => _padded(
        ManoOtpField(value: context.knobs.string(label: 'Code', initialValue: '1234')),
      ),
      'Error': (context) => _padded(
        const ManoOtpField(
          value: '',
          errorText: 'Ese código no es correcto. Te quedan 4 intentos.',
        ),
      ),
      'Busy': (context) => _padded(const ManoOtpField(value: '123456', enabled: false)),
    }),
    component('ManoResendTimer', {
      'Counting down': (context) => _padded(ManoResendTimer(onResend: noop)),
      'Ready': (context) => _padded(ManoResendTimer(onResend: noop, wait: Duration.zero)),
    }),
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
    component('ManoChoiceChip', {
      'Selectable': (context) => _padded(
        Wrap(
          spacing: ManoSpacing.sm,
          children: [
            ManoChoiceChip(
              label: context.knobs.string(label: 'Label', initialValue: 'Plomería'),
              selected: context.knobs.boolean(label: 'Selected', initialValue: true),
              onTap: noop,
            ),
            ManoChoiceChip(label: 'Pintura', onTap: noop),
          ],
        ),
      ),
      'Removable': (context) => _padded(
        ManoChoiceChip(label: 'Chapinero', onRemove: noop),
      ),
    }),
    component('ManoSupportForm', {
      'Default': (context) => _padded(
        ManoSupportForm(
          kinds: const ['Petición', 'Queja', 'Reclamo', 'Sugerencia'],
          selectedKind: context.knobs.int.slider(label: 'Kind', initialValue: 0, min: 0, max: 3),
          onKind: (_) {},
          subject: TextEditingController(),
          description: TextEditingController(),
          onChanged: noop,
          subjectError: context.knobs.stringOrNull(label: 'Subject error'),
        ),
      ),
    }),
    component('ManoStarInput', {
      'Interactive': (context) => _padded(const _StarInputDemo()),
      'Chosen': (context) => _padded(
        ManoStarInput(
          value: context.knobs.int.slider(label: 'Stars', initialValue: 4, min: 0, max: 5),
          onChanged: (_) {},
        ),
      ),
    }),
    component('ManoPhotoPickerGrid', {
      'Empty': (context) => _padded(ManoPhotoPickerGrid(photos: const [], onAdd: noop)),
      'Uploading, done and failed': (context) => _padded(
        ManoPhotoPickerGrid(
          photos: const [
            ManoPickedPhoto(id: 'a', image: NetworkImage(sampleListingPhoto)),
            ManoPickedPhoto(
              id: 'b',
              image: NetworkImage(sampleListingPhoto),
              status: ManoPhotoStatus.uploading,
            ),
            ManoPickedPhoto(
              id: 'c',
              image: NetworkImage(sampleListingPhoto),
              status: ManoPhotoStatus.failed,
            ),
          ],
          onAdd: noop,
          onRemove: (_) {},
          onRetry: (_) {},
        ),
      ),
      'Full': (context) => _padded(
        ManoPhotoPickerGrid(
          photos: [
            for (var i = 0; i < 3; i++)
              ManoPickedPhoto(id: '$i', image: const NetworkImage(sampleListingPhoto)),
          ],
          maxPhotos: 3,
          onAdd: noop,
          onRemove: (_) {},
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
    component('ManoCategoryTile', {
      'Default': (context) => _padded(
        SizedBox(
          width: 180,
          child: ManoCategoryTile(
            image: const _TilePhoto(),
            label: context.knobs.string(label: 'Label', initialValue: 'Limpieza'),
            onTap: noop,
          ),
        ),
      ),
      'Grid': (context) => _padded(
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          childAspectRatio: 2.2,
          crossAxisSpacing: ManoSpacing.md,
          mainAxisSpacing: ManoSpacing.sm,
          children: [
            for (final c in _categories) ManoCategoryTile(image: const _TilePhoto(), label: c.label, onTap: noop),
            const ManoCategoryTile(image: _TilePhoto(), label: 'Reparaciones eléctricas y de iluminación', onTap: noop),
          ],
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
      'With attach': (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ManoMessageComposer(hintText: 'Escribe un mensaje', onSend: (_) {}, onAttach: noop),
      ),
      'Pending photos': (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ManoMessageComposer(
          hintText: 'Escribe un mensaje',
          onSend: (_) {},
          onAttach: noop,
          onRemoveAttachment: (_) {},
          onRetryAttachment: (_) {},
          canSend: context.knobs.boolean(label: 'Can send', initialValue: false),
          attachments: [
            const ManoPickedPhoto(id: 'a', image: NetworkImage(sampleListingPhoto)),
            ManoPickedPhoto(
              id: 'b',
              image: const NetworkImage(sampleListingPhoto),
              status: context.knobs.object.segmented(
                label: 'Second photo',
                options: ManoPhotoStatus.values,
                initialOption: ManoPhotoStatus.uploading,
                labelBuilder: (s) => s.name,
              ),
            ),
          ],
        ),
      ),
    }),
    component('ManoAmountPad', {
      'Default': (context) => _padded(
        SizedBox(width: 360, child: _AmountPadDemo()),
      ),
    }),
  ],
);

class _AmountPadDemo extends StatefulWidget {
  @override
  State<_AmountPadDemo> createState() => _AmountPadDemoState();
}

class _AmountPadDemoState extends State<_AmountPadDemo> {
  String _digits = '1800000';

  @override
  Widget build(BuildContext context) => ManoAmountPad(
    amountLabel: ManoFormat.cop(int.tryParse(_digits) ?? 0),
    helperText: 'Opcional. Los profesionales cotizan igual.',
    onDigit: (d) => setState(() => _digits = '$_digits$d'),
    onBackspace: () => setState(
      () => _digits = _digits.isEmpty ? '' : _digits.substring(0, _digits.length - 1),
    ),
  );
}

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
    blockedDays: {DateTime(2026, 10, 9), DateTime(2026, 10, 10)},
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

// Stands in for the app's category photo; widgetbook ships no app assets.
class _TilePhoto extends StatelessWidget {
  const _TilePhoto();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: ManoColors.stone,
    child: Icon(Icons.image_outlined, color: ManoColors.faint),
  );
}

class _StarInputDemo extends StatefulWidget {
  const _StarInputDemo();

  @override
  State<_StarInputDemo> createState() => _StarInputDemoState();
}

class _StarInputDemoState extends State<_StarInputDemo> {
  var _stars = 0;

  @override
  Widget build(BuildContext context) =>
      ManoStarInput(value: _stars, onChanged: (v) => setState(() => _stars = v));
}
