import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

final _now = DateTime(2026, 10, 4, 12);

ProviderContainer _container() => ProviderContainer.test(
  overrides: [
    availabilityRepositoryProvider.overrideWithValue(
      MockAvailabilityRepository(now: () => _now),
    ),
  ],
);

AvailabilityActions _actions(ProviderContainer c) =>
    c.read(availabilityActionsProvider.notifier);

const _sunday = AvailabilityRule(
  weekdays: {DateTime.sunday},
  startMinutes: 10 * 60,
  durationMinutes: 120,
);

final SlotRange _range = (
  workerId: 'worker-1',
  from: DateTime(2026, 10, 11),
  to: DateTime(2026, 10, 12),
);

void main() {
  group('reads', () {
    test('myAvailabilityRulesProvider lists the rules', () async {
      final rules = await _container().read(myAvailabilityRulesProvider.future);
      expect(rules.map((r) => r.id), ['rule-1', 'rule-2', 'rule-3']);
    });

    test('blocks and feed start empty', () async {
      final c = _container();
      expect(await c.read(myCalendarBlocksProvider.future), isEmpty);
      expect(await c.read(myCalendarFeedProvider.future), isNull);
    });
  });

  group('rules', () {
    test('saveRule stores the rule and refreshes the list', () async {
      final c = _container();
      await c.read(myAvailabilityRulesProvider.future);

      final result = await _actions(c).saveRule(_sunday);

      expect(result.valueOrNull?.id, isNotNull);
      final rules = await c.read(myAvailabilityRulesProvider.future);
      expect(rules.last.weekdays, {DateTime.sunday});
    });

    test('saveRule rejects an invalid rule', () async {
      final result = await _actions(_container()).saveRule(
        const AvailabilityRule(
          weekdays: {},
          startMinutes: 0,
          durationMinutes: 60,
        ),
      );
      expect(result.failureOrNull, isA<DataRejected>());
    });

    test('saveRule refreshes the requester booking slots', () async {
      final c = _container();
      final sub = c.listen(availableSlotsProvider(_range), (_, _) {});
      expect(await c.read(availableSlotsProvider(_range).future), isEmpty);

      await _actions(c).saveRule(_sunday);

      expect(await c.read(availableSlotsProvider(_range).future), isNotEmpty);
      sub.close();
    });

    test('deleteRule removes it from the list', () async {
      final c = _container();
      await c.read(myAvailabilityRulesProvider.future);

      final result = await _actions(c).deleteRule('rule-3');

      expect(result.isOk, isTrue);
      final rules = await c.read(myAvailabilityRulesProvider.future);
      expect(rules.map((r) => r.id), isNot(contains('rule-3')));
    });
  });

  group('blocks', () {
    test('block adds a block and unblock removes it', () async {
      final c = _container();
      await c.read(myCalendarBlocksProvider.future);

      final added = await _actions(c).block(
        DateTime(2026, 10, 12),
        DateTime(2026, 10, 15),
        reason: 'Vacaciones',
      );
      final blocks = await c.read(myCalendarBlocksProvider.future);
      expect(blocks.single.reason, 'Vacaciones');

      await _actions(c).unblock(added.valueOrNull!.id);
      expect(await c.read(myCalendarBlocksProvider.future), isEmpty);
    });

    test('block hides the slots it covers', () async {
      final c = _container();
      await _actions(c).saveRule(_sunday);
      final sub = c.listen(availableSlotsProvider(_range), (_, _) {});
      expect(await c.read(availableSlotsProvider(_range).future), isNotEmpty);

      await _actions(c).block(_range.from, _range.to);

      expect(await c.read(availableSlotsProvider(_range).future), isEmpty);
      sub.close();
    });
  });

  group('feed', () {
    test('issueFeed then revokeFeed', () async {
      final c = _container();
      await c.read(myCalendarFeedProvider.future);

      final issued = await _actions(c).issueFeed();
      expect(await c.read(myCalendarFeedProvider.future), issued.valueOrNull);

      await _actions(c).revokeFeed();
      expect(await c.read(myCalendarFeedProvider.future), isNull);
    });
  });
}
