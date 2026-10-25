import 'package:mano_data/src/gateway/service_lookup.dart';
import 'package:test/test.dart';

import 'counting_catalog.dart';

void main() {
  test('resolves each service once, however often it is asked', () async {
    final catalog = CountingCatalog();
    final lookup = ServiceLookup(catalog);

    final results = await Future.wait([lookup('s1'), lookup('s1')]);
    await lookup('s1');

    expect(results.map((s) => s?.title), everyElement('Reparación de fugas'));
    expect(catalog.lookups, ['s1']);
  });

  test('remembers an unknown service as null', () async {
    final catalog = CountingCatalog();
    final lookup = ServiceLookup(catalog);

    expect(await lookup('nope'), isNull);
    expect(await lookup('nope'), isNull);
    expect(catalog.lookups, ['nope']);
  });

  test('a failed lookup is not remembered', () async {
    final catalog = CountingCatalog(failNext: true);
    final lookup = ServiceLookup(catalog);

    await expectLater(lookup('s1'), throwsStateError);
    expect((await lookup('s1'))?.category, 'plumbing');
    expect(catalog.lookups, ['s1', 's1']);
  });
}
