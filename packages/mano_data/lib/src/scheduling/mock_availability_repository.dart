import 'package:mano_domain/mano_domain.dart';

/// In-memory [AvailabilityRepository]; computes hourly slots from its rules.
final class MockAvailabilityRepository implements AvailabilityRepository {
  MockAvailabilityRepository({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  int _nextId = 100;
  CalendarFeed? _feed;
  final List<CalendarBlock> _blocks = [];
  final List<AvailabilityRule> _rules = [
    const AvailabilityRule(
      id: 'rule-1',
      weekdays: {1, 2, 3, 4, 5},
      startMinutes: 8 * 60,
      durationMinutes: 4 * 60,
    ),
    const AvailabilityRule(
      id: 'rule-2',
      weekdays: {1, 2, 3, 4, 5},
      startMinutes: 14 * 60,
      durationMinutes: 4 * 60,
    ),
    const AvailabilityRule(
      id: 'rule-3',
      weekdays: {DateTime.saturday},
      startMinutes: 9 * 60,
      durationMinutes: 4 * 60,
    ),
  ];

  @override
  Future<List<AvailableSlot>> slotsFor(
    String workerId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final now = _now();
    final earliest = from.isAfter(now) ? from : now;
    final slots = <AvailableSlot>[];
    for (
      var day = DateTime(from.year, from.month, from.day);
      day.isBefore(to);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      for (final rule in _rules.where(
        (r) => r.weekdays.contains(day.weekday),
      )) {
        for (
          var m = rule.startMinutes;
          m + 60 <= rule.startMinutes + rule.durationMinutes;
          m += 60
        ) {
          final start = day.add(Duration(minutes: m));
          final end = start.add(const Duration(hours: 1));
          if (start.isBefore(earliest) ||
              !start.isBefore(to) ||
              _blocked(start, end)) {
            continue;
          }
          // A deterministic sprinkle of taken slots, so the grid looks real.
          slots.add(
            AvailableSlot(
              start: start,
              end: end,
              bookable: (start.day + start.hour) % 4 != 0,
            ),
          );
        }
      }
    }
    return slots;
  }

  bool _blocked(DateTime start, DateTime end) =>
      _blocks.any((b) => start.isBefore(b.end) && end.isAfter(b.start));

  @override
  Future<List<AvailabilityRule>> myRules() async => List.of(_rules);

  @override
  Future<Result<AvailabilityRule, DataFailure>> upsertRule(
    AvailabilityRule rule,
  ) async {
    if (!rule.isValid) return const Err(DataRejected(reason: 'invalid rule'));
    final saved = rule.id == null ? rule.withId('rule-${_nextId++}') : rule;
    final index = _rules.indexWhere((r) => r.id == saved.id);
    if (index < 0) {
      _rules.add(saved);
    } else {
      _rules[index] = saved;
    }
    return Ok(saved);
  }

  @override
  Future<Result<void, DataFailure>> removeRule(String id) async {
    final before = _rules.length;
    _rules.removeWhere((r) => r.id == id);
    return _rules.length < before ? const Ok(null) : const Err(DataNotFound());
  }

  @override
  Future<List<CalendarBlock>> myBlocks() async => List.of(_blocks);

  @override
  Future<Result<CalendarBlock, DataFailure>> block(
    DateTime start,
    DateTime end, {
    String? reason,
  }) async {
    if (!end.isAfter(start)) {
      return const Err(DataRejected(reason: 'empty block'));
    }
    final block = CalendarBlock(
      id: 'block-${_nextId++}',
      start: start,
      end: end,
      reason: reason,
    );
    _blocks.add(block);
    return Ok(block);
  }

  @override
  Future<Result<void, DataFailure>> unblock(String id) async {
    final before = _blocks.length;
    _blocks.removeWhere((b) => b.id == id);
    return _blocks.length < before ? const Ok(null) : const Err(DataNotFound());
  }

  @override
  Future<CalendarFeed?> myFeed() async => _feed;

  @override
  Future<Result<CalendarFeed, DataFailure>> issueFeed() async {
    final feed = CalendarFeed(
      url: 'https://api.mano.co/calendars/mock-${_nextId++}.ics',
      issuedAt: _now(),
    );
    _feed = feed;
    return Ok(feed);
  }

  @override
  Future<Result<void, DataFailure>> revokeFeed() async {
    _feed = null;
    return const Ok(null);
  }
}
