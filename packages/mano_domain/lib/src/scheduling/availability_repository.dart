import '../result.dart';
import '../shared/data_failure.dart';
import 'availability.dart';

abstract interface class AvailabilityRepository {
  /// What a requester can book with [workerId] between [from] and [to].
  Future<List<AvailableSlot>> slotsFor(
    String workerId, {
    required DateTime from,
    required DateTime to,
  });

  Future<List<AvailabilityRule>> myRules();

  Future<Result<AvailabilityRule, DataFailure>> upsertRule(
    AvailabilityRule rule,
  );

  Future<Result<void, DataFailure>> removeRule(String id);

  Future<List<CalendarBlock>> myBlocks();

  Future<Result<CalendarBlock, DataFailure>> block(
    DateTime start,
    DateTime end, {
    String? reason,
  });

  Future<Result<void, DataFailure>> unblock(String id);

  /// Null when no link is live. Never rotates the link, and never reveals its URL.
  Future<CalendarFeedStatus?> myFeed();

  /// Issues a new link, invalidating any previous one; the only place a URL exists.
  Future<Result<CalendarFeed, DataFailure>> issueFeed();

  Future<Result<void, DataFailure>> revokeFeed();
}
