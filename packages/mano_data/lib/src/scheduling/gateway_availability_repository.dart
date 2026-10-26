import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_failure.dart';
import '../gateway/gateway_transport.dart';
import 'rrule_codec.dart';

/// [AvailabilityRepository] backed by the gateway's scheduler operations (D4).
final class GatewayAvailabilityRepository implements AvailabilityRepository {
  GatewayAvailabilityRepository(this._transport, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final GatewayTransport _transport;
  final DateTime Function() _now;

  // Rules speak the provider's wall clock; Mano operates in Colombia only.
  static const _timezone = 'America/Bogota';

  static const _ruleFields = 'id rrule durationMinutes';
  static const _blockFields = 'id start end reason';
  static const _feedFields = 'url createdAt';

  static const _slotsQuery = '''
query Slots(\$workerId: ID!, \$from: Date!, \$to: Date!) {
  workerAvailability(workerId: \$workerId, from: \$from, to: \$to) { start end bookable }
}''';

  @override
  Future<List<AvailableSlot>> slotsFor(
    String workerId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final data = await _transport.run(
      _slotsQuery,
      variables: {
        'workerId': workerId,
        'from': _date(from),
        'to': _date(_isMidnight(to) ? to : _nextDay(to)),
      },
    );
    return _list(data['workerAvailability'])
        .map(
          (json) => AvailableSlot(
            start: _instant(json['start']),
            end: _instant(json['end']),
            bookable: json['bookable'] as bool,
          ),
        )
        .where((s) => !s.start.isBefore(from) && s.start.isBefore(to))
        .toList();
  }

  @override
  Future<List<AvailabilityRule>> myRules() async {
    final data = await _transport.run(
      'query { myAvailabilityRules { $_ruleFields } }',
    );
    // Rules the app cannot represent (set elsewhere) are skipped.
    return _list(data['myAvailabilityRules']).map(_toRule).nonNulls.toList();
  }

  @override
  Future<Result<AvailabilityRule, DataFailure>> upsertRule(
    AvailabilityRule rule,
  ) async {
    if (!rule.isValid) return const Err(DataRejected(reason: 'invalid rule'));
    final wire = encodeRule(rule);
    final result = await guardGateway(() async {
      final data = await _transport.run(
        '''
mutation Upsert(\$input: AvailabilityRuleInput!) {
  upsertAvailabilityRule(input: \$input) { $_ruleFields }
}''',
        variables: {
          'input': {
            'id': ?rule.id,
            'rrule': wire.rrule,
            'durationMinutes': wire.durationMinutes,
            'validFrom': _date(_now()),
            'timezone': _timezone,
          },
        },
      );
      return _toRule(data['upsertAvailabilityRule'] as Map<String, dynamic>);
    });
    return switch (result) {
      Ok(value: final saved?) => Ok(saved),
      Ok() => const Err(DataRejected(reason: 'unrepresentable rule')),
      Err(:final failure) => Err(failure),
    };
  }

  @override
  Future<Result<void, DataFailure>> removeRule(String id) =>
      _flag('removeAvailabilityRule', id);

  @override
  Future<List<CalendarBlock>> myBlocks() async {
    final data = await _transport.run(
      'query { myCalendarBlocks { $_blockFields } }',
    );
    return _list(data['myCalendarBlocks']).map(_toBlock).toList();
  }

  @override
  Future<Result<CalendarBlock, DataFailure>> block(
    DateTime start,
    DateTime end, {
    String? reason,
  }) => guardGateway(() async {
    final data = await _transport.run(
      '''
mutation Block(\$input: CalendarBlockInput!) {
  blockCalendar(input: \$input) { $_blockFields }
}''',
      variables: {
        'input': {
          'start': start.toUtc().toIso8601String(),
          'end': end.toUtc().toIso8601String(),
          'reason': ?reason,
        },
      },
    );
    return _toBlock(data['blockCalendar'] as Map<String, dynamic>);
  });

  @override
  Future<Result<void, DataFailure>> unblock(String id) =>
      _flag('unblockCalendar', id);

  // A read-only status; the URL only comes back from regenerateCalendarFeed.
  @override
  Future<CalendarFeedStatus?> myFeed() async {
    final data = await _transport.run(
      'query { myCalendarFeed { active createdAt } }',
    );
    final json = data['myCalendarFeed'] as Map<String, dynamic>;
    if (json['active'] != true) return null;
    return CalendarFeedStatus(issuedAt: _instant(json['createdAt']));
  }

  @override
  Future<Result<CalendarFeed, DataFailure>> issueFeed() =>
      guardGateway(() async {
        final data = await _transport.run(
          'mutation { regenerateCalendarFeed { $_feedFields } }',
        );
        return _toFeed(data['regenerateCalendarFeed'] as Map<String, dynamic>);
      });

  @override
  Future<Result<void, DataFailure>> revokeFeed() =>
      _flag('revokeCalendarFeed', null);

  // A Boolean mutation; false means there was nothing to act on.
  Future<Result<void, DataFailure>> _flag(String field, String? id) async {
    final result = await guardGateway(() async {
      final data = id == null
          ? await _transport.run('mutation { $field }')
          : await _transport.run(
              'mutation Flag(\$id: ID!) { $field(id: \$id) }',
              variables: {'id': id},
            );
      return data[field] == true;
    });
    return switch (result) {
      Ok(value: true) => const Ok(null),
      Ok() => const Err(DataNotFound()),
      Err(:final failure) => Err(failure),
    };
  }
}

Iterable<Map<String, dynamic>> _list(Object? json) =>
    (json as List<dynamic>).cast<Map<String, dynamic>>();

AvailabilityRule? _toRule(Map<String, dynamic> json) => decodeRule(
  id: json['id'] as String,
  rrule: json['rrule'] as String,
  durationMinutes: json['durationMinutes'] as int,
);

CalendarBlock _toBlock(Map<String, dynamic> json) => CalendarBlock(
  id: json['id'] as String,
  start: _instant(json['start']),
  end: _instant(json['end']),
  reason: json['reason'] as String?,
);

CalendarFeed _toFeed(Map<String, dynamic> json) => CalendarFeed(
  url: json['url'] as String,
  issuedAt: _instant(json['createdAt']),
);

DateTime _instant(Object? json) => DateTime.parse(json as String).toLocal();

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

bool _isMidnight(DateTime d) =>
    d.hour == 0 && d.minute == 0 && d.second == 0 && d.millisecond == 0;

DateTime _nextDay(DateTime d) => DateTime(d.year, d.month, d.day + 1);
