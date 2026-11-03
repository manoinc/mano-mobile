import '../catalog/service_categories.dart';
import 'provider_profile.dart';

/// What is wrong with a [ProviderProfileDraft]; the screen words it in Spanish.
enum ProviderProfileDraftProblem {
  emptyName,
  nameTooLong,
  bioTooLong,
  noSkills,
  unknownSkill,
  noZones,
  tooManyPhotos,
}

const int providerNameMaxLength = 60;
const int providerBioMaxLength = 280;
const int portfolioMaxPhotos = 9;

/// The provider's own profile while it is being edited.
final class ProviderProfileDraft {
  const ProviderProfileDraft({
    this.displayName = '',
    this.photoUrl = '',
    this.bio = '',
    this.skills = const [],
    this.zones = const [],
    this.portfolioUrls = const [],
  });

  factory ProviderProfileDraft.from(ProviderProfile profile) =>
      ProviderProfileDraft(
        displayName: profile.party.displayName,
        photoUrl: profile.party.photoUrl,
        bio: profile.bio,
        skills: profile.skills,
        zones: profile.zones,
        portfolioUrls: profile.portfolioUrls,
      );

  final String displayName;
  final String photoUrl;
  final String bio;

  /// Service category ids.
  final List<String> skills;
  final List<String> zones;
  final List<String> portfolioUrls;

  Set<ProviderProfileDraftProblem> get problems {
    final name = displayName.trim();
    final known = ServiceCategories.all.map((c) => c.id).toSet();
    return {
      if (name.isEmpty) ProviderProfileDraftProblem.emptyName,
      if (name.length > providerNameMaxLength)
        ProviderProfileDraftProblem.nameTooLong,
      if (bio.trim().length > providerBioMaxLength)
        ProviderProfileDraftProblem.bioTooLong,
      if (skills.isEmpty) ProviderProfileDraftProblem.noSkills,
      if (skills.any((s) => !known.contains(s)))
        ProviderProfileDraftProblem.unknownSkill,
      if (zones.isEmpty) ProviderProfileDraftProblem.noZones,
      if (portfolioUrls.length > portfolioMaxPhotos)
        ProviderProfileDraftProblem.tooManyPhotos,
    };
  }

  bool get isValid => problems.isEmpty;

  ProviderProfileDraft toggleSkill(String id) => copyWith(
    skills: skills.contains(id)
        ? [
            for (final s in skills)
              if (s != id) s,
          ]
        : [...skills, id],
  );

  /// Ignores a blank zone or one already listed, whatever its case.
  ProviderProfileDraft addZone(String zone) {
    final clean = zone.trim();
    final taken = zones.any((z) => z.toLowerCase() == clean.toLowerCase());
    return clean.isEmpty || taken ? this : copyWith(zones: [...zones, clean]);
  }

  ProviderProfileDraft removeZone(String zone) => copyWith(
    zones: [
      for (final z in zones)
        if (z != zone) z,
    ],
  );

  ProviderProfileDraft copyWith({
    String? displayName,
    String? photoUrl,
    String? bio,
    List<String>? skills,
    List<String>? zones,
    List<String>? portfolioUrls,
  }) => ProviderProfileDraft(
    displayName: displayName ?? this.displayName,
    photoUrl: photoUrl ?? this.photoUrl,
    bio: bio ?? this.bio,
    skills: skills ?? this.skills,
    zones: zones ?? this.zones,
    portfolioUrls: portfolioUrls ?? this.portfolioUrls,
  );

  @override
  bool operator ==(Object other) =>
      other is ProviderProfileDraft &&
      other.displayName == displayName &&
      other.photoUrl == photoUrl &&
      other.bio == bio &&
      _same(other.skills, skills) &&
      _same(other.zones, zones) &&
      _same(other.portfolioUrls, portfolioUrls);

  @override
  int get hashCode => Object.hash(
    displayName,
    photoUrl,
    bio,
    Object.hashAll(skills),
    Object.hashAll(zones),
    Object.hashAll(portfolioUrls),
  );

  @override
  String toString() => 'ProviderProfileDraft($displayName)';
}

bool _same(List<String> a, List<String> b) =>
    a.length == b.length && a.indexed.every((e) => b[e.$1] == e.$2);
