import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

const _config = ManoConfig(
  gatewayGraphQlUrl: 'http://gw/graphql',
  appRole: ManoRole.requester,
);

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

Map<String, dynamic> _body(http.Request r) =>
    jsonDecode(r.body) as Map<String, dynamic>;

Map<String, Object?> _review(String id, {int rating = 5, String? comment}) => {
  'id': id,
  'rating': rating,
  'comment': comment,
  'createdAt': '2026-11-01T15:00:00Z',
  'author': {
    'role': 'CLIENT',
    'profileId': 'c1',
    'displayName': '',
    'photoUrl': null,
  },
};

GatewayReviewRepository _repo(MockClientHandler handler) =>
    GatewayReviewRepository(
      GatewayTransport(_config, httpClient: MockClient(handler)),
    );

void main() {
  test(
    'reviewProvider sends reviewWorker with the rating and comment',
    () async {
      final repo = _repo((r) async {
        expect(
          _body(r)['query'],
          contains('reviewWorker(jobId: \$jobId, input: \$input)'),
        );
        expect(_body(r)['variables'], {
          'jobId': 'j1',
          'input': {'rating': 4, 'comment': 'Muy puntual'},
        });
        return _data({
          'reviewWorker': _review('r1', rating: 4, comment: 'Muy puntual'),
        });
      });

      final review = (await repo.reviewProvider(
        'j1',
        const ReviewDraft(stars: 4, comment: ' Muy puntual '),
      )).valueOrNull!;

      expect(review.id, 'r1');
      expect(review.stars, 4);
      expect(review.text, 'Muy puntual');
      expect(review.reviewer.id, 'c1');
      expect(review.date, DateTime.utc(2026, 11, 1, 15).toLocal());
    },
  );

  test(
    'an empty comment is sent as null and read back as empty text',
    () async {
      final repo = _repo((r) async {
        expect((_body(r)['variables'] as Map)['input'], {
          'rating': 5,
          'comment': null,
        });
        return _data({'reviewClient': _review('r2')});
      });

      final review = (await repo.reviewClient(
        'j1',
        const ReviewDraft(stars: 5),
      )).valueOrNull!;

      expect(review.text, '');
    },
  );

  test(
    'a job the reviews service has not seen finish is not yet reviewable',
    () async {
      final repo = _repo(
        (_) async => _error('FailedPrecondition: job j1 is not reviewable yet'),
      );

      final failure = (await repo.reviewProvider(
        'j1',
        const ReviewDraft(stars: 5),
      )).failureOrNull!;

      expect(failure.isNotYetReviewable, isTrue);
    },
  );

  test('an invalid draft never reaches the gateway', () async {
    final repo = _repo((_) async => fail('no call expected'));

    expect(
      (await repo.reviewProvider('j1', const ReviewDraft())).failureOrNull,
      isA<DataRejected>(),
    );
  });

  group('reading a provider', () {
    Future<http.Response> backend(http.Request r) async {
      final query = _body(r)['query'] as String;
      if (query.contains('myJobs')) {
        return _data({
          'myJobs': {
            'items': [
              {
                'id': 'j0',
                'worker': {'id': 'other'},
              },
              {
                'id': 'j1',
                'worker': {'id': 'w1'},
              },
            ],
          },
        });
      }
      expect(_body(r)['variables']['id'], 'j1');
      return _data({
        'job': {
          'worker': {
            'averageRating': 4.67,
            'ratingsCount': 3,
            'reviews': {
              'items': [_review('r1'), _review('r2', rating: 4)],
              'pageInfo': {'hasNextPage': true, 'nextCursor': 'cur-2'},
            },
          },
        },
      });
    }

    test('the rating comes from a job shared with that provider', () async {
      final rating = (await _repo(backend).providerRating('w1')).valueOrNull;
      expect(rating, const RatingSummary(average: 4.67, count: 3));
    });

    test('reviews are paged with the cursor', () async {
      final calls = <http.Request>[];
      final repo = _repo((r) {
        calls.add(r);
        return backend(r);
      });

      final page = (await repo.providerReviews(
        'w1',
        after: 'cur-1',
      )).valueOrNull!;

      expect(page.items.map((r) => r.id), ['r1', 'r2']);
      expect(page.nextCursor, 'cur-2');
      expect(_body(calls.last)['variables'], {'id': 'j1', 'after': 'cur-1'});
    });

    test('the shared job is looked up once per provider', () async {
      var lookups = 0;
      final repo = _repo((r) {
        if ((_body(r)['query'] as String).contains('myJobs')) lookups++;
        return backend(r);
      });

      await repo.providerRating('w1');
      await repo.providerReviews('w1');

      expect(lookups, 1);
    });

    test('a provider with no shared job has no ratings to show', () async {
      final repo = _repo(
        (_) async => _data({
          'myJobs': {'items': []},
        }),
      );

      expect((await repo.providerRating('w9')).valueOrNull, RatingSummary.none);
      expect((await repo.providerReviews('w9')).valueOrNull!.items, isEmpty);
    });
  });
}
