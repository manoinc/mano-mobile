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

http.Response _data(Object data) =>
    http.Response(jsonEncode({'data': data}), 200);

Map<String, dynamic> _body(http.Request r) =>
    jsonDecode(r.body) as Map<String, dynamic>;

Map<String, Object?> _worker({
  Object? rating = 4.67,
  int count = 3,
  Object? jobs = 3,
  Object? rate = 0.75,
}) => {
  'id': 'w1',
  'displayName': 'Luisa Pérez',
  'photoUrl': 'https://media/luisa.jpg',
  'phone': '3001112233',
  'email': 'luisa@mano.co',
  'workZone': 'Chapinero, Usaquén',
  'referralCode': 'RP-1a2b3c4d',
  'verification': {'isVerified': true},
  'averageRating': rating,
  'ratingsCount': count,
  'jobsCompleted': jobs,
  'completionRate': rate,
};

const _local = ProviderProfile(
  party: Party(id: '', displayName: '', photoUrl: ''),
  bio: 'Plomera certificada.',
  zones: [],
  yearsExperience: 0,
  verified: false,
  skills: ['plumbing'],
);

({GatewayProviderProfileRepository repo, MockProviderProfileRepository local})
_setUp(MockClientHandler handler) {
  final local = MockProviderProfileRepository(initial: _local);
  return (
    repo: GatewayProviderProfileRepository(
      GatewayTransport(_config, httpClient: MockClient(handler)),
      details: local,
      detailsEditor: local,
      seedName: 'Luisa',
    ),
    local: local,
  );
}

void main() {
  test('profile joins served identity with the locally kept details', () async {
    final (:repo, local: _) = _setUp((r) async {
      expect(_body(r)['query'], contains('workerProfile'));
      return _data({
        'viewer': {'workerProfile': _worker()},
      });
    });

    final profile = await repo.profile();

    expect(profile.party.id, 'w1');
    expect(profile.party.displayName, 'Luisa Pérez');
    expect(profile.party.photoUrl, 'https://media/luisa.jpg');
    expect(profile.phone, '3001112233');
    expect(profile.email, 'luisa@mano.co');
    expect(profile.zones, ['Chapinero', 'Usaquén']);
    expect(profile.verified, isTrue);
    expect(profile.bio, 'Plomera certificada.');
    expect(profile.skills, ['plumbing']);
  });

  test('a fresh worker gets a profile created from the sign-up name', () async {
    final sent = <Map<String, dynamic>>[];
    final (:repo, local: _) = _setUp((r) async {
      final body = _body(r);
      sent.add(body);
      return (body['query'] as String).contains('updateWorkerProfile')
          ? _data({'updateWorkerProfile': _worker(jobs: 0, rate: null)})
          : _data({
              'viewer': {'workerProfile': null},
            });
    });

    final profile = await repo.profile();

    expect(sent.last['variables'], {
      'input': {'displayName': 'Luisa', 'workZone': ''},
    });
    expect(profile.party.displayName, 'Luisa Pérez');
  });

  test('a blank served name reads as the sign-up name', () async {
    final (:repo, local: _) = _setUp(
      (_) async => _data({
        'viewer': {
          'workerProfile': {..._worker(), 'displayName': ''},
        },
      }),
    );

    expect((await repo.profile()).party.displayName, 'Luisa');
  });

  test('stats carry what the gateway serves and nothing invented', () async {
    final (:repo, local: _) = _setUp(
      (_) async => _data({
        'viewer': {'workerProfile': _worker()},
      }),
    );

    final stats = await repo.stats();

    expect(stats.rating, 4.67);
    expect(stats.reviewCount, 3);
    expect(stats.jobsCompleted, 3);
    expect(stats.completionRatePct, 75);
    expect(stats.responseRatePct, isNull);
  });

  test('unserved stats stay null', () async {
    final (:repo, local: _) = _setUp(
      (_) async => _data({
        'viewer': {
          'workerProfile': _worker(
            rating: null,
            count: 0,
            jobs: null,
            rate: null,
          ),
        },
      }),
    );

    final stats = await repo.stats();

    expect(stats.rating, isNull);
    expect(stats.jobsCompleted, isNull);
    expect(stats.completionRatePct, isNull);
  });

  test('the referral is the served code with no reward program', () async {
    final (:repo, local: _) = _setUp(
      (_) async => _data({
        'viewer': {'workerProfile': _worker()},
      }),
    );

    final referral = await repo.referral();

    expect(referral.code, 'RP-1a2b3c4d');
    expect(referral.reward, isNull);
  });

  test('reviews read the worker profile, newest first as served', () async {
    final (:repo, local: _) = _setUp((r) async {
      expect(_body(r)['query'], contains('reviews'));
      return _data({
        'viewer': {
          'workerProfile': {
            'reviews': {
              'items': [
                {
                  'id': 'r1',
                  'rating': 5,
                  'comment': 'Excelente',
                  'createdAt': '2026-11-01T15:00:00Z',
                  'author': {
                    'role': 'CLIENT',
                    'profileId': 'c1',
                    'displayName': 'Ana',
                    'photoUrl': null,
                  },
                },
              ],
            },
          },
        },
      });
    });

    final reviews = await repo.reviews();

    expect(reviews.single.stars, 5);
    expect(reviews.single.reviewer.displayName, 'Ana');
  });

  test('save sends name and zones live and keeps the rest locally', () async {
    final sent = <Map<String, dynamic>>[];
    final (:repo, :local) = _setUp((r) async {
      final body = _body(r);
      sent.add(body);
      return (body['query'] as String).contains('updateWorkerProfile')
          ? _data({'updateWorkerProfile': _worker()})
          : _data({
              'viewer': {'workerProfile': _worker()},
            });
    });

    const draft = ProviderProfileDraft(
      displayName: 'Luisa Pérez',
      bio: 'Nueva bio',
      skills: ['plumbing'],
      zones: ['Chapinero', 'Usaquén'],
    );
    final result = await repo.save(draft);

    expect(sent.first['variables'], {
      'input': {'displayName': 'Luisa Pérez', 'workZone': 'Chapinero, Usaquén'},
    });
    expect((await local.profile()).bio, 'Nueva bio');
    expect(result.valueOrNull?.bio, 'Nueva bio');
  });

  test('an invalid draft is refused before calling', () async {
    final (:repo, local: _) = _setUp(
      (_) async => fail('must not call the gateway'),
    );

    final result = await repo.save(const ProviderProfileDraft());

    expect(result.failureOrNull, isA<DataRejected>());
  });
}
