import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  const profile = ProviderProfile(
    party: Party(id: 'p1', displayName: 'Andrés Castro', photoUrl: 'a.jpg'),
    bio: 'Plomero',
    zones: ['Chapinero'],
    yearsExperience: 8,
    verified: true,
    skills: ['plumbing'],
    portfolioUrls: ['w1.jpg'],
  );

  final valid = ProviderProfileDraft.from(profile);

  test('starts from the saved profile', () {
    expect(valid.displayName, 'Andrés Castro');
    expect(valid.photoUrl, 'a.jpg');
    expect(valid.bio, 'Plomero');
    expect(valid.skills, ['plumbing']);
    expect(valid.zones, ['Chapinero']);
    expect(valid.portfolioUrls, ['w1.jpg']);
    expect(valid.isValid, isTrue);
  });

  test('a name is required and short enough', () {
    expect(
      valid.copyWith(displayName: '  ').problems,
      contains(ProviderProfileDraftProblem.emptyName),
    );
    expect(
      valid.copyWith(displayName: 'a' * 61).problems,
      contains(ProviderProfileDraftProblem.nameTooLong),
    );
  });

  test('the bio has a maximum length', () {
    expect(valid.copyWith(bio: 'a' * providerBioMaxLength).isValid, isTrue);
    expect(
      valid.copyWith(bio: 'a' * (providerBioMaxLength + 1)).problems,
      contains(ProviderProfileDraftProblem.bioTooLong),
    );
  });

  test('needs at least one known skill', () {
    expect(
      valid.copyWith(skills: []).problems,
      contains(ProviderProfileDraftProblem.noSkills),
    );
    expect(
      valid.copyWith(skills: ['astrology']).problems,
      contains(ProviderProfileDraftProblem.unknownSkill),
    );
  });

  test('needs at least one work zone', () {
    expect(
      valid.copyWith(zones: []).problems,
      contains(ProviderProfileDraftProblem.noZones),
    );
  });

  test('keeps at most nine portfolio photos', () {
    final nine = List.generate(portfolioMaxPhotos, (i) => '$i.jpg');
    expect(valid.copyWith(portfolioUrls: nine).isValid, isTrue);
    expect(
      valid.copyWith(portfolioUrls: [...nine, 'x.jpg']).problems,
      contains(ProviderProfileDraftProblem.tooManyPhotos),
    );
  });

  test('toggling a skill adds or removes it', () {
    expect(valid.toggleSkill('cleaning').skills, ['plumbing', 'cleaning']);
    expect(valid.toggleSkill('plumbing').skills, isEmpty);
  });

  test('zones are added once, trimmed, and removed', () {
    expect(valid.addZone('  Usaquén ').zones, ['Chapinero', 'Usaquén']);
    expect(valid.addZone('chapinero').zones, ['Chapinero']);
    expect(valid.addZone('   ').zones, ['Chapinero']);
    expect(valid.removeZone('Chapinero').zones, isEmpty);
  });

  test('equal drafts compare equal, so the screen can tell it is dirty', () {
    expect(ProviderProfileDraft.from(profile), valid);
    expect(valid.copyWith(bio: 'otro'), isNot(valid));
    expect(valid.copyWith(skills: ['plumbing']), valid);
  });
}
