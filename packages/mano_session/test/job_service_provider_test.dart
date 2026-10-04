import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

const _service = JobService(
  id: 'svc-1',
  category: 'Limpieza',
  title: 'Limpieza profunda',
  description: '',
);

final class _Catalog implements ServiceCatalog {
  int calls = 0;

  @override
  Future<JobService?> service(String id) async {
    calls++;
    if (id == 'boom') throw StateError('gateway down');
    return id == _service.id ? _service : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('jobServiceProvider resolves a title, null when unknown', () async {
    final c = ProviderContainer.test(
      overrides: [serviceCatalogProvider.overrideWithValue(_Catalog())],
    );
    expect(await c.read(jobServiceProvider('svc-1').future), _service);
    expect(await c.read(jobServiceProvider('nope').future), isNull);
  });

  test('jobServiceProvider does not retry on its own', () async {
    final catalog = _Catalog();
    // A plain container keeps Riverpod's default retry, which the test helper turns off.
    final c = ProviderContainer(
      overrides: [serviceCatalogProvider.overrideWithValue(catalog)],
    );
    addTearDown(c.dispose);
    c.listen(jobServiceProvider('boom'), (_, _) {});
    await expectLater(
      c.read(jobServiceProvider('boom').future),
      throwsStateError,
    );
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(catalog.calls, 1);
  });
}
