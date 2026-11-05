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

GatewayTransport _transport(MockClientHandler handler) =>
    GatewayTransport(_config, httpClient: MockClient(handler));

Map<String, dynamic> _body(http.Request r) =>
    jsonDecode(r.body) as Map<String, dynamic>;

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

const _quoteJson = {
  'id': 'q1',
  'worker': {'id': 'w1', 'displayName': '', 'photoUrl': null},
  'amount': {'amount': 1150000.4, 'currency': 'COP'},
  'message': 'Incluye materiales',
  'status': 'SUBMITTED',
  'createdAt': '2026-10-20T15:00:00Z',
};

const _projectJson = {
  'id': 'p1',
  'category': 'Pintura',
  'title': 'Pintar sala',
  'description': 'Sala de 30 m²',
  'photos': ['https://x/1.jpg'],
  'estimatedBudget': {'amount': 1800000, 'currency': 'COP'},
  'status': 'OPEN',
  'createdAt': '2026-10-20T14:00:00Z',
};

final _quote = Quote(
  id: 'q1',
  projectId: 'p1',
  projectTitle: 'Pintar sala',
  worker: const Party(id: 'w1', displayName: '', photoUrl: ''),
  amountCop: 1150000,
  message: 'Incluye materiales',
  status: QuoteStatus.submitted,
  createdAt: DateTime.utc(2026, 10, 20, 15),
);

Project _project({List<Quote>? quotes}) => Project(
  id: 'p1',
  category: ServiceCategories.painting,
  title: 'Pintar sala',
  description: 'Sala de 30 m²',
  photoUrls: const ['https://x/1.jpg'],
  budgetCop: 1800000,
  status: ProjectStatus.open,
  createdAt: DateTime.utc(2026, 10, 20, 14),
  quotes: quotes,
);

void main() {
  group('GatewayProjectRepository', () {
    test(
      'mine asks for 50 projects with 50 quotes each and maps them',
      () async {
        final repo = GatewayProjectRepository(
          _transport((r) async {
            final query = _body(r)['query'] as String;
            expect(query, contains('myProjects(page: {first: 50})'));
            expect(query, contains('quotes(page: {first: 50})'));
            return _data({
              'myProjects': {
                'items': [
                  {
                    ..._projectJson,
                    'quotes': {
                      'items': [_quoteJson],
                    },
                  },
                  {
                    ..._projectJson,
                    'id': 'p2',
                    'estimatedBudget': null,
                    'status': 'AWARDED',
                    'quotes': {'items': []},
                  },
                ],
              },
            });
          }),
        );

        final mine = await repo.mine();

        expect(mine.first, _project(quotes: [_quote]));
        expect(mine.last.budgetCop, isNull);
        expect(mine.last.status, ProjectStatus.awarded);
        expect(mine.last.quotes, isEmpty);
      },
    );

    test('publish sends the trimmed draft', () async {
      final repo = GatewayProjectRepository(
        _transport((r) async {
          expect(_body(r)['variables'], {
            'input': {
              'category': 'painting',
              'title': 'Pintar sala',
              'description': 'Sala de 30 m²',
              'photos': <String>[],
              'estimatedBudget': 1800000,
            },
          });
          return _data({
            'publishProject': {
              ..._projectJson,
              'quotes': {'items': []},
            },
          });
        }),
      );

      final result = await repo.publish(
        const ProjectDraft(
          category: ServiceCategories.painting,
          title: ' Pintar sala ',
          description: 'Sala de 30 m² ',
          budgetCop: 1800000,
        ),
      );

      expect(result, Ok<Project, DataFailure>(_project(quotes: const [])));
    });

    test('publish sends the uploaded photos in order', () async {
      final repo = GatewayProjectRepository(
        _transport((r) async {
          expect(((_body(r)['variables'] as Map)['input'] as Map)['photos'], [
            'https://x/1.jpg',
            'https://x/2.jpg',
          ]);
          return _data({
            'publishProject': {
              ..._projectJson,
              'quotes': {'items': []},
            },
          });
        }),
      );

      await repo.publish(
        const ProjectDraft(
          category: ServiceCategories.painting,
          title: 'Pintar sala',
          description: 'Sala de 30 m²',
          photoUrls: ['https://x/1.jpg', 'https://x/2.jpg'],
        ),
      );
    });

    test('publish refuses an invalid draft without calling', () async {
      final repo = GatewayProjectRepository(
        _transport((_) async => fail('should not call')),
      );
      expect(
        (await repo.publish(const ProjectDraft())).failureOrNull,
        isA<DataRejected>(),
      );
    });

    test('cancel sends the id and maps a refusal', () async {
      final repo = GatewayProjectRepository(
        _transport((r) async {
          expect(_body(r)['variables'], {'id': 'p1'});
          return _error('FailedPrecondition: project is CLOSED');
        }),
      );
      expect(
        (await repo.cancel('p1')).failureOrNull,
        isA<DataRejected>().having(
          (f) => f.reason,
          'reason',
          'FailedPrecondition: project is CLOSED',
        ),
      );
    });

    test('cancel maps the cancelled project', () async {
      final repo = GatewayProjectRepository(
        _transport(
          (_) async => _data({
            'cancelProject': {
              ..._projectJson,
              'status': 'CANCELLED',
              'quotes': {'items': []},
            },
          }),
        ),
      );
      expect(
        (await repo.cancel('p1')).valueOrNull?.status,
        ProjectStatus.cancelled,
      );
    });

    test('select and discard send the quote id and map the quote', () async {
      final sent = <String>[];
      final repo = GatewayProjectRepository(
        _transport((r) async {
          final body = _body(r);
          sent.add(body['variables']['id'] as String);
          final field = (body['query'] as String).contains('selectQuote')
              ? 'selectQuote'
              : 'discardQuote';
          return _data({
            field: {
              ..._quoteJson,
              'status': field == 'selectQuote' ? 'SELECTED' : 'DISCARDED',
              'project': {'id': 'p1', 'title': 'Pintar sala'},
            },
          });
        }),
      );

      final selected = await repo.selectQuote('q1');
      final discarded = await repo.discardQuote('q2');

      expect(
        selected.valueOrNull,
        _quote.copyWith(status: QuoteStatus.selected),
      );
      expect(discarded.valueOrNull?.status, QuoteStatus.discarded);
      expect(sent, ['q1', 'q2']);
    });

    test('a quote of a stranger\'s project is not found', () async {
      final repo = GatewayProjectRepository(
        _transport((_) async => _error('NotFound: quote')),
      );
      expect((await repo.selectQuote('q1')).failureOrNull, isA<DataNotFound>());
    });
  });

  group('GatewayLeadRepository', () {
    test(
      'openProjects passes the category and maps projects without quotes',
      () async {
        final repo = GatewayLeadRepository(
          _transport((r) async {
            final body = _body(r);
            expect(body['variables'], {'category': 'painting'});
            expect(body['query'], contains('first: 50'));
            expect(body['query'], isNot(contains('quotes')));
            return _data({
              'openProjects': {
                'items': [_projectJson],
              },
            });
          }),
        );

        expect(await repo.openProjects(category: ServiceCategories.painting), [
          _project(),
        ]);
      },
    );

    test('openProjects without a category sends null', () async {
      final repo = GatewayLeadRepository(
        _transport((r) async {
          expect(_body(r)['variables'], {'category': null});
          return _data({
            'openProjects': {'items': []},
          });
        }),
      );
      expect(await repo.openProjects(), isEmpty);
    });

    test('submitQuote sends amount and message and maps the quote', () async {
      final repo = GatewayLeadRepository(
        _transport((r) async {
          expect(_body(r)['variables'], {
            'projectId': 'p1',
            'input': {'amount': 1150000, 'message': 'Incluye materiales'},
          });
          return _data({
            'submitQuote': {
              ..._quoteJson,
              'project': {'id': 'p1', 'title': 'Pintar sala'},
            },
          });
        }),
      );

      final result = await repo.submitQuote(
        'p1',
        amountCop: 1150000,
        message: 'Incluye materiales',
      );

      expect(result.valueOrNull, _quote);
    });

    test('a second quote is reported as already quoted', () async {
      final repo = GatewayLeadRepository(
        _transport(
          (_) async => _error('AlreadyExists: worker already quoted project'),
        ),
      );

      final result = await repo.submitQuote('p1', amountCop: 1);

      expect(result.failureOrNull, isA<DataRejected>());
      expect(result.failureOrNull!.isAlreadyQuoted, isTrue);
    });

    test('myQuotes maps each quote with its project', () async {
      final repo = GatewayLeadRepository(
        _transport((r) async {
          expect(_body(r)['query'], contains('myQuotes(page: {first: 50})'));
          return _data({
            'myQuotes': {
              'items': [
                {
                  ..._quoteJson,
                  'status': 'SELECTED',
                  'project': {'id': 'p1', 'title': 'Pintar sala'},
                },
              ],
            },
          });
        }),
      );

      expect(await repo.myQuotes(), [
        _quote.copyWith(status: QuoteStatus.selected),
      ]);
    });

    test('purchaseLead sends the quote and maps the unlocked quote', () async {
      final repo = GatewayLeadRepository(
        _transport((r) async {
          final body = _body(r);
          expect(body['query'], contains('purchaseProjectLead'));
          expect(body['variables'], {'quoteId': 'q1'});
          return _data({
            'purchaseProjectLead': {
              ..._quoteJson,
              'status': 'SELECTED',
              'leadPurchased': true,
              'project': {'id': 'p1', 'title': 'Pintar sala'},
            },
          });
        }),
      );
      final bought = (await repo.purchaseLead('q1')).valueOrNull!;
      expect(bought.status, QuoteStatus.selected);
      expect(bought.leadPurchased, isTrue);
      expect(bought.id, 'q1');
    });

    test('purchaseLead without enough coins is InsufficientCoins', () async {
      final repo = GatewayLeadRepository(
        _transport(
          (_) async => _error(
            'FailedPrecondition: the provider does not have enough coins',
          ),
        ),
      );
      expect(
        (await repo.purchaseLead('q1')).failureOrNull,
        const InsufficientCoins(),
      );
    });

    test('purchaseLead keeps any other refusal a refusal', () async {
      final repo = GatewayLeadRepository(
        _transport(
          (_) async => _error(
            'FailedPrecondition: only the selected worker can buy this lead',
          ),
        ),
      );
      expect(
        (await repo.purchaseLead('q1')).failureOrNull,
        isA<DataRejected>(),
      );
    });
  });
}
