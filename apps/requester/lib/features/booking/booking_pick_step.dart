import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'booking_sheets.dart';

/// Pick a day and one of the professional's open slots.
class BookingPickStep extends ConsumerWidget {
  const BookingPickStep({
    required this.offer,
    required this.serviceTitle,
    required this.onPropose,
    super.key,
  });

  final ServiceOffer offer;
  final String serviceTitle;
  final VoidCallback onPropose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final booking = ref.watch(bookingProvider(offer.id));
    final notifier = ref.read(bookingProvider(offer.id).notifier);
    final range = (
      workerId: offer.offerantId,
      from: booking.range.from,
      to: booking.range.to,
    );
    final slots = ref.watch(availableSlotsProvider(range));
    final slot = booking.selectedSlot;

    return ManoStepScaffold(
      headline: 'Agenda tu cita',
      onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      primaryLabel: 'Continuar',
      busy: booking.status is BookingSubmitting,
      onPrimary: slot == null
          ? null
          : () => _continue(context, ref, notifier, slot),
      children: [
        _Summary(title: serviceTitle, offer: offer),
        const SizedBox(height: ManoSpacing.xl),
        switch (slots) {
          AsyncData(:final value) => _Calendar(
            days: booking.days,
            slots: value,
            selectedDay: booking.selectedDay,
            selectedSlot: slot,
            onDay: notifier.selectDay,
            onSlot: notifier.selectSlot,
          ),
          AsyncError() => Row(
            children: [
              Expanded(
                child: Text(
                  'No pudimos cargar los horarios.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: ManoColors.muted,
                  ),
                ),
              ),
              ManoTextAction(
                label: 'Reintentar',
                onPressed: () => ref.invalidate(availableSlotsProvider(range)),
              ),
            ],
          ),
          _ => const SizedBox(height: 72, child: Center(child: ManoLoader())),
        },
        if (booking.status case BookingFailed(:final failure)) ...[
          const SizedBox(height: ManoSpacing.lg),
          ManoNotice(message: failure.message, tone: ManoNoticeTone.error),
        ],
        const SizedBox(height: ManoSpacing.lg),
        ManoQuietButton(label: 'Proponer otro horario', onPressed: onPropose),
      ],
    );
  }

  Future<void> _continue(
    BuildContext context,
    WidgetRef ref,
    BookingNotifier notifier,
    DateTime slot,
  ) async {
    if (!isSignedIn(ref)) return showAccountNeededSheet(context, ref);
    final confirmed = await showConfirmBookingSheet(
      context,
      serviceTitle: serviceTitle,
      start: slot,
      offer: offer,
    );
    if (confirmed) await notifier.confirm();
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.title, required this.offer});

  final String title;
  final ServiceOffer offer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final price = priceLabels(offer);
    return Container(
      padding: const EdgeInsets.all(ManoSpacing.md),
      decoration: BoxDecoration(
        color: ManoColors.sand,
        borderRadius: BorderRadius.circular(ManoRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleLarge),
          const SizedBox(height: ManoSpacing.xs),
          ManoPriceTag(amountLabel: price.amount, rateLabel: price.rate),
          if (offer.rateType == RateType.hourly) ...[
            const SizedBox(height: ManoSpacing.sm),
            Text(
              hourlyNote,
              style: textTheme.bodySmall?.copyWith(color: ManoColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.days,
    required this.slots,
    required this.selectedDay,
    required this.selectedSlot,
    required this.onDay,
    required this.onSlot,
  });

  final List<DateTime> days;
  final List<AvailableSlot> slots;
  final DateTime? selectedDay;
  final DateTime? selectedSlot;
  final ValueChanged<DateTime> onDay;
  final ValueChanged<DateTime> onSlot;

  bool _bookableOn(DateTime day) =>
      slots.any((s) => s.bookable && DateUtils.isSameDay(s.start, day));

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final daySlots = selectedDay == null
        ? const <AvailableSlot>[]
        : slots
              .where((s) => DateUtils.isSameDay(s.start, selectedDay))
              .toList();
    final anyOpen = days.any(_bookableOn);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Elige un día', style: textTheme.titleMedium),
        const SizedBox(height: ManoSpacing.sm),
        ManoDateStrip(
          days: days,
          selected: selectedDay,
          weekdayLabel: ManoFormat.weekdayShort,
          isEnabled: _bookableOn,
          onSelected: onDay,
        ),
        const SizedBox(height: ManoSpacing.lg),
        Text('Elige una hora', style: textTheme.titleMedium),
        const SizedBox(height: ManoSpacing.sm),
        ManoSlotGrid(
          slots: [
            for (final s in daySlots)
              ManoSlot(label: ManoFormat.time(s.start), enabled: s.bookable),
          ],
          selectedIndex: _indexOf(daySlots),
          onSelected: (i) => onSlot(daySlots[i].start),
          emptyLabel: !anyOpen
              ? 'No hay horarios en las próximas dos semanas. '
                    'Puedes proponer otro horario.'
              : selectedDay == null
              ? 'Elige un día para ver los horarios.'
              : 'No hay horarios este día.',
        ),
      ],
    );
  }

  int? _indexOf(List<AvailableSlot> daySlots) {
    final i = daySlots.indexWhere((s) => s.start == selectedSlot);
    return i < 0 ? null : i;
  }
}
