import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

final class _Catalog implements ServiceCatalog {
  _Catalog({this.fail = false});

  final bool fail;
  final calls = <({String? category, String? text})>[];

  @override
  Future<List<JobService>> search({String? category, String? text}) async {
    calls.add((category: category, text: text));
    if (fail) throw Exception('gateway down');
    return const [
      JobService(
        id: 's1',
        category: 'cleaning',
        title: 'Aseo',
        description: '',
      ),
    ];
  }

  @override
  Future<JobService?> service(String id) async => null;
  @override
  Future<ServiceOffer?> offer(String id) async => null;
  @override
  Future<List<ServiceOffer>> offersFor(String jobServiceId) async => [];
}

ProviderContainer _container(_Catalog catalog) => ProviderContainer.test(
  overrides: [serviceCatalogProvider.overrideWithValue(catalog)],
);

void main() {
  group('ServiceQuery', () {
    test('trims text and treats blanks as no filter', () {
      const query = ServiceQuery(category: ' ', text: '  aseo ');
      expect(query.searchText, 'aseo');
      expect(query.categoryFilter, isNull);
      expect(const ServiceQuery().searchText, isNull);
    });

    test('queries that differ only in whitespace are equal', () {
      expect(
        const ServiceQuery(category: 'cleaning', text: 'aseo '),
        const ServiceQuery(category: 'cleaning', text: ' aseo'),
      );
      expect(
        const ServiceQuery(category: 'cleaning').hashCode,
        const ServiceQuery(category: 'cleaning', text: '  ').hashCode,
      );
    });

    test('copyWith can clear the category', () {
      const query = ServiceQuery(category: 'cleaning', text: 'aseo');
      expect(query.copyWith(category: () => null).categoryFilter, isNull);
      expect(query.copyWith(text: 'tubo').searchText, 'tubo');
      expect(query.copyWith(text: 'tubo').categoryFilter, 'cleaning');
    });
  });

  group('serviceSearchProvider', () {
    test('passes the normalized filters to the catalog', () async {
      final catalog = _Catalog();
      final results = await _container(catalog).read(
        serviceSearchProvider(
          const ServiceQuery(category: 'cleaning', text: ' aseo '),
        ).future,
      );

      expect(results.single.id, 's1');
      expect(catalog.calls.single, (category: 'cleaning', text: 'aseo'));
    });

    test('an empty query asks for everything', () async {
      final catalog = _Catalog();
      await _container(catalog)
          .read(serviceSearchProvider(const ServiceQuery()).future);

      expect(catalog.calls.single, (category: null, text: null));
    });

    test(
      'a failure surfaces as an error right away, without retrying',
      () async {
        final container = _container(_Catalog(fail: true));
        final sub = container.listen(
          serviceSearchProvider(const ServiceQuery()),
          (_, _) {},
        );

        await expectLater(
          container.read(serviceSearchProvider(const ServiceQuery()).future),
          throwsException,
        );
        expect(sub.read().hasError, isTrue);
        expect(sub.read().isLoading, isFalse);
      },
    );
  });
}
