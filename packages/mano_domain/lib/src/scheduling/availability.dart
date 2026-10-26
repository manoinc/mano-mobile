/// A recurring weekly window in which a provider takes work.
final class AvailabilityRule {
  const AvailabilityRule({
    required this.weekdays,
    required this.startMinutes,
    required this.durationMinutes,
    this.id,
  });

  /// Null until the backend has stored it.
  final String? id;

  /// [DateTime.monday] through [DateTime.sunday].
  final Set<int> weekdays;

  /// Minutes after local midnight.
  final int startMinutes;
  final int durationMinutes;

  static const int _slotMinutes = 30;
  static const int _day = 24 * 60;

  bool get isValid =>
      weekdays.isNotEmpty &&
      weekdays.every((d) => d >= DateTime.monday && d <= DateTime.sunday) &&
      startMinutes >= 0 &&
      durationMinutes > 0 &&
      durationMinutes % _slotMinutes == 0 &&
      startMinutes + durationMinutes <= _day;

  AvailabilityRule withId(String id) => AvailabilityRule(
    id: id,
    weekdays: weekdays,
    startMinutes: startMinutes,
    durationMinutes: durationMinutes,
  );

  @override
  bool operator ==(Object other) =>
      other is AvailabilityRule &&
      other.id == id &&
      other.weekdays.length == weekdays.length &&
      other.weekdays.containsAll(weekdays) &&
      other.startMinutes == startMinutes &&
      other.durationMinutes == durationMinutes;

  @override
  int get hashCode => Object.hash(
    id,
    Object.hashAllUnordered(weekdays),
    startMinutes,
    durationMinutes,
  );

  @override
  String toString() =>
      'AvailabilityRule($id, $weekdays, $startMinutes+$durationMinutes)';
}

/// A bookable (or already taken) slot computed from rules, blocks and jobs.
final class AvailableSlot {
  const AvailableSlot({
    required this.start,
    required this.end,
    required this.bookable,
  });

  final DateTime start;
  final DateTime end;
  final bool bookable;

  @override
  bool operator ==(Object other) =>
      other is AvailableSlot &&
      other.start == start &&
      other.end == end &&
      other.bookable == bookable;

  @override
  int get hashCode => Object.hash(start, end, bookable);

  @override
  String toString() => 'AvailableSlot($start, bookable: $bookable)';
}

/// A one-off period the provider will not work.
final class CalendarBlock {
  const CalendarBlock({
    required this.id,
    required this.start,
    required this.end,
    this.reason,
  });

  final String id;
  final DateTime start;
  final DateTime end;
  final String? reason;

  @override
  bool operator ==(Object other) =>
      other is CalendarBlock &&
      other.id == id &&
      other.start == start &&
      other.end == end &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(id, start, end, reason);

  @override
  String toString() => 'CalendarBlock($id, $start–$end)';
}

/// A private subscription link to the provider's agenda (.ics), known only when issued.
final class CalendarFeed {
  const CalendarFeed({required this.url, required this.issuedAt});

  final String url;
  final DateTime issuedAt;

  CalendarFeedStatus get status => CalendarFeedStatus(issuedAt: issuedAt);

  @override
  bool operator ==(Object other) =>
      other is CalendarFeed && other.url == url && other.issuedAt == issuedAt;

  @override
  int get hashCode => Object.hash(url, issuedAt);

  @override
  String toString() => 'CalendarFeed($url)';
}

/// That a feed link is live, without its URL: reading it never rotates the link.
final class CalendarFeedStatus {
  const CalendarFeedStatus({required this.issuedAt});

  final DateTime issuedAt;

  @override
  bool operator ==(Object other) =>
      other is CalendarFeedStatus && other.issuedAt == issuedAt;

  @override
  int get hashCode => issuedAt.hashCode;

  @override
  String toString() => 'CalendarFeedStatus($issuedAt)';
}
