import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mano_session/mano_session.dart';

// The default mock repositories are fresh per container, so most tests need no overrides.

/// When the mock job fixtures start: `days` from today at `hour`.
DateTime mockJobStart(int days, int hour) {
  final today = DateTime.now();
  return DateTime(today.year, today.month, today.day + days, hour);
}

List<Override> emptyAgenda() => [
  myJobsProvider.overrideWith((ref) async => const <Job>[]),
];

List<Override> failingAgenda() => [
  myJobsProvider.overrideWith((ref) async => throw StateError('offline')),
];

/// Pins the hour logger's clock to [now].
Override clockAt(DateTime now) =>
    agendaClockProvider.overrideWithValue(() => now);
