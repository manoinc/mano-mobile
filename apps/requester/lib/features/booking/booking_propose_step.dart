import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'booking_sheets.dart';

/// Ask the professional for a time outside their open slots.
class BookingProposeStep extends ConsumerStatefulWidget {
  const BookingProposeStep({
    required this.offer,
    required this.onBack,
    super.key,
  });

  final ServiceOffer offer;
  final VoidCallback onBack;

  @override
  ConsumerState<BookingProposeStep> createState() => _BookingProposeStepState();
}

class _BookingProposeStepState extends ConsumerState<BookingProposeStep> {
  static const _hours = [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18];

  final _message = TextEditingController();
  DateTime? _day;
  int? _hour;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  DateTime _at(DateTime day, int hour) =>
      DateTime(day.year, day.month, day.day, hour);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final booking = ref.watch(bookingProvider(widget.offer.id));
    final now = DateTime.now();
    final day = _day;
    final hour = _hour;
    final ready =
        _message.text.trim().isNotEmpty && day != null && hour != null;

    return ManoStepScaffold(
      headline: 'Propón otro horario',
      subhead: 'El profesional revisará tu propuesta y te responderá.',
      onBack: widget.onBack,
      primaryLabel: 'Enviar solicitud',
      busy: booking.status is BookingSubmitting,
      onPrimary: ready ? () => _submit(_at(day, hour)) : null,
      children: [
        ManoTextField(
          label: 'Mensaje',
          controller: _message,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: ManoSpacing.xl),
        Text('Día', style: textTheme.titleMedium),
        const SizedBox(height: ManoSpacing.sm),
        ManoDateStrip(
          days: booking.days,
          selected: day,
          weekdayLabel: ManoFormat.weekdayShort,
          onSelected: (d) => setState(() {
            _day = d;
            _hour = null;
          }),
        ),
        const SizedBox(height: ManoSpacing.lg),
        Text('Hora', style: textTheme.titleMedium),
        const SizedBox(height: ManoSpacing.sm),
        ManoSlotGrid(
          slots: [
            if (day != null)
              for (final h in _hours)
                ManoSlot(
                  label: ManoFormat.time(_at(day, h)),
                  enabled: _at(day, h).isAfter(now),
                ),
          ],
          selectedIndex: hour == null ? null : _hours.indexOf(hour),
          onSelected: (i) => setState(() => _hour = _hours[i]),
          emptyLabel: 'Elige un día primero.',
        ),
        if (booking.status case BookingFailed(:final failure)) ...[
          const SizedBox(height: ManoSpacing.lg),
          ManoNotice(message: failure.message, tone: ManoNoticeTone.error),
        ],
      ],
    );
  }

  Future<void> _submit(DateTime start) async {
    if (!isSignedIn(ref)) return showAccountNeededSheet(context, ref);
    await ref
        .read(bookingProvider(widget.offer.id).notifier)
        .propose(message: _message.text.trim(), start: start);
  }
}
