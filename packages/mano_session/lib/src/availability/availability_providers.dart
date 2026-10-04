import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../booking/booking_notifier.dart';
import '../marketplace_providers.dart';

final myAvailabilityRulesProvider = FutureProvider<List<AvailabilityRule>>(
  (ref) => ref.watch(availabilityRepositoryProvider).myRules(),
);

final myCalendarBlocksProvider = FutureProvider<List<CalendarBlock>>(
  (ref) => ref.watch(availabilityRepositoryProvider).myBlocks(),
);

final myCalendarFeedProvider = FutureProvider<CalendarFeed?>(
  (ref) => ref.watch(availabilityRepositoryProvider).myFeed(),
);

/// Availability mutations; each success invalidates the reads it changed.
final class AvailabilityActions extends Notifier<void> {
  @override
  void build() {}

  AvailabilityRepository get _repo => ref.read(availabilityRepositoryProvider);

  Future<Result<AvailabilityRule, DataFailure>> saveRule(
    AvailabilityRule rule,
  ) async {
    final result = await _repo.upsertRule(rule);
    if (result.isOk) _changed(myAvailabilityRulesProvider);
    return result;
  }

  Future<Result<void, DataFailure>> deleteRule(String id) async {
    final result = await _repo.removeRule(id);
    if (result.isOk) _changed(myAvailabilityRulesProvider);
    return result;
  }

  Future<Result<CalendarBlock, DataFailure>> block(
    DateTime start,
    DateTime end, {
    String? reason,
  }) async {
    final result = await _repo.block(start, end, reason: reason);
    if (result.isOk) _changed(myCalendarBlocksProvider);
    return result;
  }

  Future<Result<void, DataFailure>> unblock(String id) async {
    final result = await _repo.unblock(id);
    if (result.isOk) _changed(myCalendarBlocksProvider);
    return result;
  }

  Future<Result<CalendarFeed, DataFailure>> issueFeed() async {
    final result = await _repo.issueFeed();
    if (result.isOk) ref.invalidate(myCalendarFeedProvider);
    return result;
  }

  Future<Result<void, DataFailure>> revokeFeed() async {
    final result = await _repo.revokeFeed();
    if (result.isOk) ref.invalidate(myCalendarFeedProvider);
    return result;
  }

  // Rules and blocks shape what requesters can book, so their slots go stale too.
  void _changed(FutureProvider<Object> provider) {
    ref
      ..invalidate(provider)
      ..invalidate(availableSlotsProvider);
  }
}

final availabilityActionsProvider =
    NotifierProvider<AvailabilityActions, void>(AvailabilityActions.new);
