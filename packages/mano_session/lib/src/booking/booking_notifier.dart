import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../marketplace_providers.dart';

/// Whose calendar and which stretch of it to read.
typedef SlotRange = ({String workerId, DateTime from, DateTime to});

final availableSlotsProvider = FutureProvider.autoDispose
    .family<List<AvailableSlot>, SlotRange>(
      (ref, r) => ref
          .watch(availabilityRepositoryProvider)
          .slotsFor(r.workerId, from: r.from, to: r.to),
    );

sealed class BookingStatus {
  const BookingStatus();
}

final class BookingIdle extends BookingStatus {
  const BookingIdle();
}

final class BookingSubmitting extends BookingStatus {
  const BookingSubmitting();
}

final class BookingFailed extends BookingStatus {
  const BookingFailed(this.failure);

  final DataFailure failure;
}

final class BookingBooked extends BookingStatus {
  const BookingBooked(this.job);

  final Job job;
}

final class BookingRequested extends BookingStatus {
  const BookingRequested(this.request);

  final ServiceRequest request;
}

final class BookingState {
  const BookingState({
    required this.days,
    this.selectedDay,
    this.selectedSlot,
    this.status = const BookingIdle(),
  });

  static const windowDays = 14;

  /// The bookable window, one local midnight per day.
  final List<DateTime> days;
  final DateTime? selectedDay;

  /// The chosen slot's start.
  final DateTime? selectedSlot;
  final BookingStatus status;

  ({DateTime from, DateTime to}) get range =>
      (from: days.first, to: days.last.add(const Duration(days: 1)));

  BookingState copyWith({
    DateTime? selectedDay,
    DateTime? Function()? selectedSlot,
    BookingStatus? status,
  }) => BookingState(
    days: days,
    selectedDay: selectedDay ?? this.selectedDay,
    selectedSlot: selectedSlot == null ? this.selectedSlot : selectedSlot(),
    status: status ?? this.status,
  );
}

/// One booking attempt against one offer: pick a day and slot, then book or propose.
class BookingNotifier extends Notifier<BookingState> {
  BookingNotifier(this.offerId);

  final String offerId;

  @override
  BookingState build() {
    final now = DateTime.now();
    return BookingState(
      days: [
        for (var i = 0; i < BookingState.windowDays; i++)
          DateTime(now.year, now.month, now.day + i),
      ],
    );
  }

  void selectDay(DateTime day) => state = state.copyWith(
    selectedDay: day,
    selectedSlot: () => null,
    status: const BookingIdle(),
  );

  void selectSlot(DateTime start) => state = state.copyWith(
    selectedSlot: () => start,
    status: const BookingIdle(),
  );

  Future<void> confirm() async {
    final slot = state.selectedSlot;
    if (slot == null || state.status is BookingSubmitting) return;
    state = state.copyWith(status: const BookingSubmitting());
    final result = await ref.read(jobRepositoryProvider).bookSlot(offerId, slot);
    if (!ref.mounted) return;
    state = state.copyWith(
      status: switch (result) {
        Ok(:final value) => BookingBooked(value),
        Err(:final failure) => BookingFailed(failure),
      },
    );
    if (result.isOk) ref.invalidate(myJobsProvider);
  }

  Future<void> propose({
    required String message,
    required DateTime start,
  }) async {
    if (state.status is BookingSubmitting) return;
    state = state.copyWith(status: const BookingSubmitting());
    final result = await ref
        .read(serviceRequestRepositoryProvider)
        .request(offerId, message: message, proposedStart: start);
    if (!ref.mounted) return;
    state = state.copyWith(
      status: switch (result) {
        Ok(:final value) => BookingRequested(value),
        Err(:final failure) => BookingFailed(failure),
      },
    );
    if (result.isOk) ref.invalidate(myServiceRequestsProvider);
  }
}

final bookingProvider = NotifierProvider.autoDispose
    .family<BookingNotifier, BookingState, String>(BookingNotifier.new);
