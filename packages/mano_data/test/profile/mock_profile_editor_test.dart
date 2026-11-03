import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

void main() {
  late MockProviderProfileRepository repo;

  setUp(() => repo = MockProviderProfileRepository());

  test('the profile starts with skills and portfolio photos', () async {
    final profile = await repo.profile();
    expect(profile.skills, isNotEmpty);
    expect(profile.portfolioUrls, isNotEmpty);
    expect(ProviderProfileDraft.from(profile).isValid, isTrue);
  });

  test('a saved draft is what the profile reads afterwards', () async {
    final draft = ProviderProfileDraft.from(await repo.profile()).copyWith(
      displayName: 'Andrés C.',
      photoUrl: 'new.jpg',
      bio: 'Nuevo bio',
      skills: ['painting'],
      zones: ['Suba'],
      portfolioUrls: ['w.jpg'],
    );

    final saved = await repo.save(draft);

    expect(saved.isOk, isTrue);
    final profile = await repo.profile();
    expect(profile.party.displayName, 'Andrés C.');
    expect(profile.party.photoUrl, 'new.jpg');
    expect(profile.bio, 'Nuevo bio');
    expect(profile.skills, ['painting']);
    expect(profile.zones, ['Suba']);
    expect(profile.portfolioUrls, ['w.jpg']);
    expect(profile.verified, isTrue);
  });

  test('an invalid draft is rejected and nothing changes', () async {
    final before = await repo.profile();
    final result = await repo.save(
      ProviderProfileDraft.from(before).copyWith(displayName: ''),
    );
    expect(result.failureOrNull, isA<DataRejected>());
    expect((await repo.profile()).party.displayName, before.party.displayName);
  });
}
