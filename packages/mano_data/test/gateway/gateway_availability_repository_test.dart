import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

const _config = ManoConfig(
  gatewayGraphQlUrl: 'http://gw/graphql',
  appRole: ManoRole.provider,
);

GatewayAvailabilityRepository _repo(MockClientHandler handler) =>
    GatewayAvailabilityRepository(
      GatewayTransport(_config, httpClient: MockClient(handler)),
      now: () => DateTime(2026, 10, 25, 22, 15),
    );

Map<String, dynamic> _body(http.Request r) =>
    jsonDecode(r.body) as Map<String, dynamic>;

String _query(http.Request r) => _body(r)['query'] as String;

Object? _vars(http.Request r) => _body(r)['variables'];

http.Response _data(Object data) =>
    http.Response(jsonEncode({'data': data}), 200);

http.Response _error(String message) => http.Response(
  jsonEncode({
    'errors': [
      {'message': message},
    ],
  }),
  200,
);

void main() {
  group('slotsFor', () {
    test('asks for whole days covering the range, to exclusive', () async {
      final repo = _repo((r) async {
        expect(_query(r), contains('workerAvailability'));
        expect(_vars(r), {
          'workerId': 'w1',
          'from': '2026-10-26',
          'to': '2026-10-28',
        });
        return _data({'workerAvailability': []});
      });

      await repo.slotsFor(
        'w1',
        from: DateTime(2026, 10, 26, 9),
        to: DateTime(2026, 10, 27, 18),
      );
    });

    test('a range ending at midnight does not ask for the next day', () async {
      final repo = _repo((r) async {
        expect(_vars(r), {
          'workerId': 'w1',
          'from': '2026-10-26',
          'to': '2026-11-02',
        });
        return _data({'workerAvailability': []});
      });

      await repo.slotsFor(
        'w1',
        from: DateTime(2026, 10, 26),
        to: DateTime(2026, 11, 2),
      );
    });

    test(
      'maps slots to local time and drops those outside the range',
      () async {
        final start = DateTime(2026, 10, 26, 9);
        String utc(DateTime d) => d.toUtc().toIso8601String();
        final repo = _repo(
          (_) async => _data({
            'workerAvailability': [
              {
                'start': utc(DateTime(2026, 10, 26, 8)),
                'end': utc(DateTime(2026, 10, 26, 9)),
                'bookable': true,
              },
              {
                'start': utc(start),
                'end': utc(DateTime(2026, 10, 26, 10)),
                'bookable': false,
              },
              {
                'start': utc(DateTime(2026, 10, 26, 12)),
                'end': utc(DateTime(2026, 10, 26, 13)),
                'bookable': true,
              },
            ],
          }),
        );

        final slots = await repo.slotsFor(
          'w1',
          from: start,
          to: DateTime(2026, 10, 26, 12),
        );

        expect(slots, [
          AvailableSlot(
            start: start,
            end: DateTime(2026, 10, 26, 10),
            bookable: false,
          ),
        ]);
        expect(slots.single.start.isUtc, isFalse);
      },
    );
  });

  group('rules', () {
    test('myRules decodes rules and skips what it cannot represent', () async {
      final repo = _repo((r) async {
        expect(_query(r), contains('myAvailabilityRules'));
        return _data({
          'myAvailabilityRules': [
            {
              'id': 'r1',
              'rrule': 'FREQ=WEEKLY;BYDAY=MO,WE;BYHOUR=8;BYMINUTE=0',
              'durationMinutes': 240,
              'validFrom': '2026-10-01',
              'validUntil': null,
              'timezone': 'America/Bogota',
            },
            {
              'id': 'r2',
              'rrule': 'FREQ=DAILY;BYHOUR=8',
              'durationMinutes': 60,
              'validFrom': '2026-10-01',
              'validUntil': null,
              'timezone': 'America/Bogota',
            },
          ],
        });
      });

      expect(await repo.myRules(), const [
        AvailabilityRule(
          id: 'r1',
          weekdays: {1, 3},
          startMinutes: 480,
          durationMinutes: 240,
        ),
      ]);
    });

    test('upsertRule sends a new rule with today as validFrom', () async {
      final repo = _repo((r) async {
        expect(_query(r), contains('upsertAvailabilityRule'));
        expect(_vars(r), {
          'input': {
            'rrule': 'FREQ=WEEKLY;BYDAY=SA;BYHOUR=9;BYMINUTE=0',
            'durationMinutes': 120,
            'validFrom': '2026-10-25',
            'timezone': 'America/Bogota',
          },
        });
        return _data({
          'upsertAvailabilityRule': {
            'id': 'r7',
            'rrule': 'FREQ=WEEKLY;BYDAY=SA;BYHOUR=9;BYMINUTE=0',
            'durationMinutes': 120,
          },
        });
      });

      final result = await repo.upsertRule(
        const AvailabilityRule(
          weekdays: {6},
          startMinutes: 540,
          durationMinutes: 120,
        ),
      );

      expect(
        result.valueOrNull,
        const AvailabilityRule(
          id: 'r7',
          weekdays: {6},
          startMinutes: 540,
          durationMinutes: 120,
        ),
      );
    });

    test('upsertRule sends the id of a stored rule to replace it', () async {
      final repo = _repo((r) async {
        expect((_vars(r)! as Map)['input'], containsPair('id', 'r1'));
        return _data({
          'upsertAvailabilityRule': {
            'id': 'r1',
            'rrule': 'FREQ=WEEKLY;BYDAY=MO;BYHOUR=8;BYMINUTE=0',
            'durationMinutes': 60,
          },
        });
      });

      final result = await repo.upsertRule(
        const AvailabilityRule(
          id: 'r1',
          weekdays: {1},
          startMinutes: 480,
          durationMinutes: 60,
        ),
      );
      expect(result.isOk, isTrue);
    });

    test('an invalid rule is rejected without a call', () async {
      final repo = _repo((_) async => fail('no call expected'));
      final result = await repo.upsertRule(
        const AvailabilityRule(
          weekdays: {},
          startMinutes: 0,
          durationMinutes: 30,
        ),
      );
      expect(result.failureOrNull, isA<DataRejected>());
    });

    test('a rejected upsert is a failure', () async {
      final repo = _repo((_) async => _error('InvalidArgument: grid'));
      final result = await repo.upsertRule(
        const AvailabilityRule(
          weekdays: {1},
          startMinutes: 0,
          durationMinutes: 30,
        ),
      );
      expect(result.failureOrNull, isA<DataRejected>());
    });

    test('removeRule passes the id', () async {
      final repo = _repo((r) async {
        expect(_query(r), contains('removeAvailabilityRule'));
        expect(_vars(r), {'id': 'r1'});
        return _data({'removeAvailabilityRule': true});
      });
      expect((await repo.removeRule('r1')).isOk, isTrue);
    });

    test('removeRule answering false is DataNotFound', () async {
      final repo = _repo((_) async => _data({'removeAvailabilityRule': false}));
      expect((await repo.removeRule('r9')).failureOrNull, const DataNotFound());
    });
  });

  group('blocks', () {
    test('myBlocks maps blocks to local time', () async {
      final start = DateTime(2026, 10, 27, 8);
      final end = DateTime(2026, 10, 27, 12);
      final repo = _repo((r) async {
        expect(_query(r), contains('myCalendarBlocks'));
        return _data({
          'myCalendarBlocks': [
            {
              'id': 'b1',
              'start': start.toUtc().toIso8601String(),
              'end': end.toUtc().toIso8601String(),
              'reason': 'Cita médica',
            },
          ],
        });
      });

      expect(await repo.myBlocks(), [
        CalendarBlock(id: 'b1', start: start, end: end, reason: 'Cita médica'),
      ]);
    });

    test('block sends UTC instants', () async {
      final start = DateTime(2026, 10, 27, 8);
      final end = DateTime(2026, 10, 27, 12);
      final repo = _repo((r) async {
        expect(_query(r), contains('blockCalendar'));
        expect(_vars(r), {
          'input': {
            'start': start.toUtc().toIso8601String(),
            'end': end.toUtc().toIso8601String(),
            'reason': 'Viaje',
          },
        });
        return _data({
          'blockCalendar': {
            'id': 'b2',
            'start': start.toUtc().toIso8601String(),
            'end': end.toUtc().toIso8601String(),
            'reason': 'Viaje',
          },
        });
      });

      final result = await repo.block(start, end, reason: 'Viaje');

      expect(
        result.valueOrNull,
        CalendarBlock(id: 'b2', start: start, end: end, reason: 'Viaje'),
      );
    });

    test('block leaves out a missing reason', () async {
      final start = DateTime.utc(2026, 10, 27, 13);
      final repo = _repo((r) async {
        expect((_vars(r)! as Map)['input'], isNot(contains('reason')));
        return _data({
          'blockCalendar': {
            'id': 'b3',
            'start': '2026-10-27T13:00:00Z',
            'end': '2026-10-27T14:00:00Z',
            'reason': null,
          },
        });
      });
      final result = await repo.block(
        start,
        start.add(const Duration(hours: 1)),
      );
      expect(result.valueOrNull?.reason, isNull);
    });

    test('unblock passes the id; false is DataNotFound', () async {
      final repo = _repo((r) async {
        expect(_query(r), contains('unblockCalendar'));
        expect(_vars(r), {'id': 'b1'});
        return _data({'unblockCalendar': false});
      });
      expect((await repo.unblock('b1')).failureOrNull, const DataNotFound());
    });
  });

  group('feed', () {
    final feedJson = {
      'url': 'https://gw/calendar/abc.ics',
      'createdAt': '2026-10-25T15:00:00Z',
    };
    final feed = CalendarFeed(
      url: 'https://gw/calendar/abc.ics',
      issuedAt: DateTime.utc(2026, 10, 25, 15).toLocal(),
    );

    test('myFeed reads the status of the live link', () async {
      final repo = _repo((r) async {
        expect(_query(r), contains('myCalendarFeed'));
        expect(_query(r), contains('active'));
        return _data({
          'myCalendarFeed': {
            'active': true,
            'createdAt': '2026-10-25T15:00:00Z',
          },
        });
      });
      expect(await repo.myFeed(), feed.status);
    });

    test('myFeed never asks for the URL nor regenerates the link', () async {
      final queries = <String>[];
      final repo = _repo((r) async {
        queries.add(_query(r));
        return _data({
          'myCalendarFeed': {
            'active': true,
            'createdAt': '2026-10-25T15:00:00Z',
          },
        });
      });
      await repo.myFeed();
      await repo.myFeed();
      expect(queries, hasLength(2));
      for (final q in queries) {
        expect(q, isNot(contains('regenerateCalendarFeed')));
        expect(q, isNot(contains('url')));
      }
    });

    test('myFeed is null when no link is active', () async {
      final repo = _repo(
        (_) async => _data({
          'myCalendarFeed': {'active': false, 'createdAt': null},
        }),
      );
      expect(await repo.myFeed(), isNull);
    });

    test('issueFeed regenerates the link', () async {
      final repo = _repo((r) async {
        expect(_query(r), contains('regenerateCalendarFeed'));
        return _data({'regenerateCalendarFeed': feedJson});
      });
      expect((await repo.issueFeed()).valueOrNull, feed);
    });

    test('revokeFeed revokes it', () async {
      final repo = _repo((r) async {
        expect(_query(r), contains('revokeCalendarFeed'));
        return _data({'revokeCalendarFeed': true});
      });
      expect((await repo.revokeFeed()).isOk, isTrue);
    });

    test('an outage on a mutation is DataUnavailable', () async {
      final repo = _repo((_) async => http.Response('', 502));
      expect((await repo.revokeFeed()).failureOrNull, isA<DataUnavailable>());
    });
  });
}
