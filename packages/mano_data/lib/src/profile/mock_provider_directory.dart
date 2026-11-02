import 'package:mano_domain/mano_domain.dart';

import '../mock/mock_fixtures.dart';

// (bio, skills, portfolio photo ids) per mock provider.
const _details = {
  'provider-1': (
    'Más de ocho años cuidando casas en Bogotá. Puntual, ordenado y siempre '
        'con los materiales listos.',
    ['Limpieza', 'Pintura', 'Plomería'],
    ['1581578731548-c64695cc6952', '1562259949-e8e7689d7828'],
  ),
  'provider-2': (
    'Plomera certificada. Fugas, calentadores y remodelaciones de baño.',
    ['Plomería', 'Remodelación'],
    ['1504148455328-c376907d081c'],
  ),
};

/// In-memory [ProviderDirectory] for the mock providers.
final class MockProviderDirectory implements ProviderDirectory {
  @override
  Future<Result<PublicProviderProfile, DataFailure>> profile(
    String providerId,
  ) async {
    final party = mockProviders.where((p) => p.id == providerId).firstOrNull;
    final details = _details[providerId];
    if (party == null || details == null) return const Err(DataNotFound());
    final (bio, skills, photos) = details;
    return Ok(
      PublicProviderProfile(
        party: party,
        bio: bio,
        verified: providerId == 'provider-1',
        skills: skills,
        portfolioUrls: [for (final p in photos) mockPhoto(p)],
      ),
    );
  }
}
