import 'package:mano_session/mano_session.dart';

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

/// The greeting name: the signed-in user's, else the profile's first name.
String? resolveGreetingName(
  AuthenticatedUser? user,
  ProviderProfile? profile,
) => greetingName(user) ?? greetingFirstName(profile);

/// The profile photo for the greeting, or null when there is none.
String? greetingPhoto(ProviderProfile? profile) {
  final url = profile?.party.photoUrl ?? '';
  return url.isEmpty ? null : url;
}
