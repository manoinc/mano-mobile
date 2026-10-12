import 'package:mano_domain/mano_domain.dart';

const _placeholders = {'profesional', 'solicitante'};

/// The name to greet, or null when there is none worth saying.
String? greetingName(AuthenticatedUser? user) {
  if (user == null) return null;
  final name = user.displayName.trim();
  if (name.isEmpty || name == user.subject) return null;
  if (_placeholders.contains(name.toLowerCase())) return null;
  return name;
}

/// The professional's first name from their profile, or null when blank.
String? greetingFirstName(ProviderProfile? profile) {
  final name = profile?.firstName.trim() ?? '';
  return name.isEmpty ? null : name;
}

/// The greeting name: the account's, else the one typed in onboarding, else the profile's.
String? resolveGreetingName(
  AuthenticatedUser? user,
  ProviderProfile? profile, {
  String onboardingName = '',
}) =>
    greetingName(user) ??
    (onboardingName.trim().isEmpty ? null : onboardingName.trim()) ??
    greetingFirstName(profile);

/// The profile photo, only when greeting the profile's own [name].
String? greetingPhoto(ProviderProfile? profile, {required String name}) {
  if (greetingFirstName(profile) != name) return null;
  final url = profile?.party.photoUrl ?? '';
  return url.isEmpty ? null : url;
}
