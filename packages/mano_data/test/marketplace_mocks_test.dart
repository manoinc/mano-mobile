import 'dart:async';

import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

final _now = DateTime(2026, 10, 5, 10);
DateTime _clock() => _now;

void main() {
  group('MockOfferManagement', () {
    late MockOfferManagement offers;
    setUp(() => offers = MockOfferManagement());

    test('starts with active and paused offers', () async {
      final statuses = {for (final o in await offers.myOffers()) o.status};
      expect(statuses, containsAll([OfferStatus.active, OfferStatus.paused]));
    });

    test('create adds an active offer', () async {
      final created = await offers.create(
        jobServiceId: 's9',
        rateType: RateType.hourly,
        amountCop: 50000,
        zone: 'Usaquén',
      );
      expect(created.valueOrNull?.status, OfferStatus.active);
      expect(await offers.myOffers(), contains(created.valueOrNull));
    });

    test('a negative amount is rejected', () async {
      final result = await offers.create(
        jobServiceId: 's9',
        rateType: RateType.fixed,
        amountCop: -1,
        zone: '',
      );
      expect(result.failureOrNull, isA<DataRejected>());
    });

    test('pause, resume and delete move the status; delete hides it', () async {
      final id = (await offers.myOffers())
          .firstWhere((o) => o.status == OfferStatus.active)
          .id;
      expect((await offers.pause(id)).valueOrNull?.status, OfferStatus.paused);
      expect((await offers.pause(id)).failureOrNull, isA<DataRejected>());
      expect((await offers.resume(id)).valueOrNull?.status, OfferStatus.active);
      expect(
        (await offers.delete(id)).valueOrNull?.status,
        OfferStatus.deleted,
      );
      expect((await offers.myOffers()).map((o) => o.id), isNot(contains(id)));
    });

    test('update changes only the given fields', () async {
      final before = (await offers.myOffers()).first;
      final after = (await offers.update(
        before.id,
        amountCop: 99000,
      )).valueOrNull!;
      expect(after.amountCop, 99000);
      expect(after.zone, before.zone);
    });

    test('an unknown id is not found', () async {
      expect((await offers.pause('nope')).failureOrNull, isA<DataNotFound>());
    });
  });

  group('MockServiceRequestRepository', () {
    late MockServiceRequestRepository requests;
    setUp(() => requests = MockServiceRequestRepository(now: _clock));

    test(
      'pending leads are real jobs: every category, zone and photos',
      () async {
        final pending = await requests.mine(
          status: ServiceRequestStatus.pending,
        );
        expect({
          for (final r in pending) r.category,
        }, ServiceCategories.all.map((c) => c.id).toSet());
        for (final r in pending) {
          expect(r.neighborhood, isNotEmpty, reason: r.id);
          expect(r.photoUrls, isNotEmpty, reason: r.id);
          expect(r.message.length, greaterThan(40), reason: r.id);
        }
      },
    );

    test('fixtures cover every status and mine filters by status', () async {
      final statuses = {for (final r in await requests.mine()) r.status};
      expect(statuses, ServiceRequestStatus.values.toSet());
      final pending = await requests.mine(status: ServiceRequestStatus.pending);
      expect(
        pending.every((r) => r.status == ServiceRequestStatus.pending),
        isTrue,
      );
    });

    test('request adds a pending request with the message and time', () async {
      final at = _now.add(const Duration(days: 2));
      final result = await requests.request(
        'offer-1',
        message: '¿Puedes el sábado?',
        proposedStart: at,
      );
      final created = result.valueOrNull!;
      expect(created.status, ServiceRequestStatus.pending);
      expect(created.message, '¿Puedes el sábado?');
      expect(created.proposedStart, at);
    });

    test('accept, reject and cancel only work on pending requests', () async {
      final id = (await requests.mine(status: ServiceRequestStatus.pending))
          .first
          .id;
      final rejected = await requests.reject(id, reason: 'Sin cupo');
      expect(rejected.valueOrNull?.status, ServiceRequestStatus.rejected);
      expect(rejected.valueOrNull?.rejectionReason, 'Sin cupo');
      expect((await requests.accept(id)).failureOrNull, isA<DataRejected>());
      expect((await requests.cancel(id)).failureOrNull, isA<DataRejected>());
    });

    test('an unknown id is not found', () async {
      expect(
        (await requests.accept('nope')).failureOrNull,
        isA<DataNotFound>(),
      );
    });
  });

  group('MockJobRepository', () {
    late MockJobRepository jobs;
    setUp(() => jobs = MockJobRepository(now: _clock));

    Future<Job> firstWith(JobStatus status, {RateType? rateType}) async =>
        (await jobs.mine(status: status))
            .firstWhere((j) => rateType == null || j.rateType == rateType);

    test(
      'fixtures cover every status, including an hourly job in progress',
      () async {
        final all = await jobs.mine();
        expect({for (final j in all) j.status}, JobStatus.values.toSet());
        expect(
          all.any(
            (j) =>
                j.status == JobStatus.inProgress &&
                j.rateType == RateType.hourly,
          ),
          isTrue,
        );
      },
    );

    test('job finds by id or returns null', () async {
      final any = (await jobs.mine()).first;
      expect(await jobs.job(any.id), any);
      expect(await jobs.job('nope'), isNull);
    });

    test('bookSlot creates a scheduled job at that time', () async {
      final at = _now.add(const Duration(days: 1));
      final job = (await jobs.bookSlot('offer-1', at)).valueOrNull!;
      expect(job.status, JobStatus.scheduled);
      expect(job.start, at);
      expect(await jobs.job(job.id), job);
    });

    test('start then finish a fixed job', () async {
      final scheduled = await firstWith(
        JobStatus.scheduled,
        rateType: RateType.fixed,
      );
      expect(
        (await jobs.start(scheduled.id)).valueOrNull?.status,
        JobStatus.inProgress,
      );
      expect(
        (await jobs.finish(scheduled.id)).valueOrNull?.status,
        JobStatus.finished,
      );
    });

    test('an hourly job needs positive hours to finish', () async {
      final hourly = await firstWith(
        JobStatus.inProgress,
        rateType: RateType.hourly,
      );
      expect((await jobs.finish(hourly.id)).failureOrNull, isA<DataRejected>());
      expect(
        (await jobs.finish(hourly.id, actualHours: 0)).failureOrNull,
        isA<DataRejected>(),
      );
      final done = (await jobs.finish(
        hourly.id,
        actualHours: 2.5,
      )).valueOrNull!;
      expect(done.status, JobStatus.finished);
      expect(done.actualHours, 2.5);
    });

    test('transitions the domain forbids are rejected', () async {
      final finished = await firstWith(JobStatus.finished);
      expect(
        (await jobs.start(finished.id)).failureOrNull,
        isA<DataRejected>(),
      );
      expect(
        (await jobs.cancel(finished.id)).failureOrNull,
        isA<DataRejected>(),
      );
    });

    test('rebook turns a finished job into a pending request', () async {
      final finished = await firstWith(JobStatus.finished);
      final request = (await jobs.rebook(finished.id)).valueOrNull!;
      expect(request.status, ServiceRequestStatus.pending);
      expect(request.serviceTitle, finished.serviceTitle);
    });
  });

  group('MockAvailabilityRepository', () {
    late MockAvailabilityRepository availability;
    setUp(() => availability = MockAvailabilityRepository(now: _clock));

    test('slots fall inside the rules and some are taken', () async {
      final slots = await availability.slotsFor(
        'p1',
        from: _now,
        to: _now.add(const Duration(days: 7)),
      );
      expect(slots, isNotEmpty);
      expect(slots.any((s) => !s.bookable), isTrue);
      expect(
        slots.every((s) => s.start.isAfter(_now) || s.start == _now),
        isTrue,
      );
    });

    test('a blocked day has no slots', () async {
      final day = DateTime(2026, 10, 6); // a Tuesday
      await availability.block(day, day.add(const Duration(days: 1)));
      final slots = await availability.slotsFor(
        'p1',
        from: day,
        to: day.add(const Duration(days: 1)),
      );
      expect(slots, isEmpty);
    });

    test(
      'upsert stores a valid rule with an id and rejects invalid ones',
      () async {
        final saved = await availability.upsertRule(
          const AvailabilityRule(
            weekdays: {DateTime.sunday},
            startMinutes: 600,
            durationMinutes: 120,
          ),
        );
        expect(saved.valueOrNull?.id, isNotNull);
        expect(await availability.myRules(), contains(saved.valueOrNull));

        final invalid = await availability.upsertRule(
          const AvailabilityRule(
            weekdays: {},
            startMinutes: 0,
            durationMinutes: 30,
          ),
        );
        expect(invalid.failureOrNull, isA<DataRejected>());
      },
    );

    test('removeRule and unblock delete by id', () async {
      final rule = (await availability.myRules()).first;
      await availability.removeRule(rule.id!);
      expect(await availability.myRules(), isNot(contains(rule)));

      final block = (await availability.block(
        _now,
        _now.add(const Duration(hours: 2)),
      )).valueOrNull!;
      await availability.unblock(block.id);
      expect(await availability.myBlocks(), isNot(contains(block)));
    });

    test(
      'issuing a feed replaces the previous one; revoking clears it',
      () async {
        expect(await availability.myFeed(), isNull);
        final first = (await availability.issueFeed()).valueOrNull!;
        final second = (await availability.issueFeed()).valueOrNull!;
        expect(second.url, isNot(first.url));
        expect(await availability.myFeed(), second.status);
        await availability.revokeFeed();
        expect(await availability.myFeed(), isNull);
      },
    );

    test('reading the feed never rotates it', () async {
      final issued = (await availability.issueFeed()).valueOrNull!;
      await availability.myFeed();
      await availability.myFeed();
      expect(await availability.myFeed(), issued.status);
    });
  });

  group('MockChatRepository', () {
    test('history is oldest first', () async {
      final chat = MockChatRepository(now: _clock);
      final messages = await chat.messages('conv-1');
      expect(messages, isNotEmpty);
      for (var i = 1; i < messages.length; i++) {
        expect(messages[i].sentAt.isBefore(messages[i - 1].sentAt), isFalse);
      }
    });

    test('send stores the message and emits it to watchers', () async {
      final chat = MockChatRepository(now: _clock);
      final emitted = <Message>[];
      final sub = chat.watch('conv-1').listen(emitted.add);

      final sent = (await chat.send('conv-1', 'Hola')).valueOrNull!;
      await Future<void>.delayed(Duration.zero);

      expect(sent.fromMe, isTrue);
      expect(sent.status, MessageStatus.sent);
      expect(emitted.first, sent);
      expect((await chat.messages('conv-1')).last.id, sent.id);
      await sub.cancel();
    });

    test('my message becomes delivered right after it is sent', () async {
      final chat = MockChatRepository(now: _clock);
      final emitted = <Message>[];
      final sub = chat.watch('conv-1').listen(emitted.add);

      final sent = (await chat.send('conv-1', 'Hola')).valueOrNull!;
      await Future<void>.delayed(Duration.zero);

      expect(emitted.map((m) => (m.id, m.status)), [
        (sent.id, MessageStatus.sent),
        (sent.id, MessageStatus.delivered),
      ]);
      expect(
        (await chat.messages('conv-1')).last.status,
        MessageStatus.delivered,
      );
      await sub.cancel();
    });

    test('the reply marks my messages read', () async {
      final chat = MockChatRepository(
        now: _clock,
        replyDelay: const Duration(milliseconds: 1),
      );
      final emitted = <Message>[];
      final sub = chat.watch('conv-2').listen(emitted.add);

      final sent = (await chat.send('conv-2', 'Hola')).valueOrNull!;
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(emitted.any((m) => !m.fromMe), isTrue);
      final mine = (await chat.messages('conv-2'))
          .where((m) => m.id == sent.id);
      expect(mine.single.status, MessageStatus.read);
      expect(
        emitted.where((m) => m.id == sent.id).map((m) => m.status).last,
        MessageStatus.read,
      );
      await sub.cancel();
    });

    test('a blank message is rejected', () async {
      final chat = MockChatRepository(now: _clock);
      expect(
        (await chat.send('conv-1', '  ')).failureOrNull,
        isA<DataRejected>(),
      );
    });

    test('with a reply delay the other side answers', () async {
      final chat = MockChatRepository(
        now: _clock,
        replyDelay: const Duration(milliseconds: 1),
      );
      final reply = chat.watch('conv-2').firstWhere((m) => !m.fromMe);
      await chat.send('conv-2', '¿Vienes mañana?');
      expect((await reply.timeout(const Duration(seconds: 1))).fromMe, isFalse);
    });
  });

  group('MockProviderOnboardingRepository', () {
    test(
      'starts unsubmitted and becomes pending after a complete submit',
      () async {
        final onboarding = MockProviderOnboardingRepository();
        expect(await onboarding.status(), VerificationStatus.notSubmitted);
        final result = await onboarding.submit(
          const WorkerProfileDraft(
            displayName: 'Andrés',
            phone: '3001234567',
            workZone: 'Chapinero',
            documentPaths: ['/tmp/cedula.jpg'],
          ),
        );
        expect(result.valueOrNull, VerificationStatus.pending);
        expect(await onboarding.status(), VerificationStatus.pending);
      },
    );

    test(
      'documents are optional; the identity check covers the cédula',
      () async {
        final onboarding = MockProviderOnboardingRepository();
        final result = await onboarding.submit(
          const WorkerProfileDraft(
            displayName: 'Andrés',
            phone: '300',
            workZone: 'Chapinero',
          ),
        );
        expect(result.valueOrNull, VerificationStatus.pending);
      },
    );

    test('a submit without a name is rejected', () async {
      final onboarding = MockProviderOnboardingRepository();
      final result = await onboarding.submit(
        const WorkerProfileDraft(displayName: ' ', phone: '300', workZone: 'x'),
      );
      expect(result.failureOrNull, isA<DataRejected>());
    });
  });
}
