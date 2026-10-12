import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('ServiceCategories', () {
    test('lists the five canonical ids in rail order', () {
      expect(ServiceCategories.all.map((c) => c.id), [
        'cleaning',
        'plumbing',
        'electrical',
        'painting',
        'gardening',
      ]);
    });

    test(
      'normalizes English, Spanish and stray casing to the canonical id',
      () {
        expect(ServiceCategories.normalize('Plumbing'), 'plumbing');
        expect(ServiceCategories.normalize(' Plomería '), 'plumbing');
        expect(ServiceCategories.normalize('JARDINERIA'), 'gardening');
        expect(ServiceCategories.normalize('Gardening'), 'gardening');
        expect(ServiceCategories.normalize('limpieza'), 'cleaning');
        expect(ServiceCategories.normalize('Electricidad'), 'electrical');
        expect(ServiceCategories.normalize('pintura'), 'painting');
      },
    );

    test('keeps an unknown category, only trimmed', () {
      expect(ServiceCategories.normalize('  Carpintería '), 'Carpintería');
    });

    test('labels a known id in Spanish and falls back to the raw text', () {
      expect(ServiceCategories.labelOf('plumbing'), 'Plomería');
      expect(ServiceCategories.labelOf('Plumbing'), 'Plomería');
      expect(ServiceCategories.labelOf('Carpintería'), 'Carpintería');
    });
  });
}
