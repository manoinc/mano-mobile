import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  const base = WorkerProfileDraft(
    displayName: 'Ana',
    phone: '3001234567',
    workZone: 'Chapinero',
  );

  test('services, experience and bio default to empty', () {
    expect(base.categories, isEmpty);
    expect(base.yearsExperience, 0);
    expect(base.bio, isEmpty);
  });

  test('equality covers the new fields', () {
    const same = WorkerProfileDraft(
      displayName: 'Ana',
      phone: '3001234567',
      workZone: 'Chapinero',
      categories: [ServiceCategories.plumbing],
      yearsExperience: 3,
      bio: 'Hola',
    );
    expect(same, isNot(base));
    expect(
      same,
      const WorkerProfileDraft(
        displayName: 'Ana',
        phone: '3001234567',
        workZone: 'Chapinero',
        categories: [ServiceCategories.plumbing],
        yearsExperience: 3,
        bio: 'Hola',
      ),
    );
  });
}
