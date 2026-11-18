import 'package:mano_domain/mano_domain.dart';

import '../onboarding/onboarding_flow.dart';

const _placeholders = {'profesional', 'solicitante'};

/// The account's name to greet, or null when there is none worth saying.
String? greetingName(AuthenticatedUser? user) {
  if (user == null) return null;
  final name = user.displayName.trim();
  if (name.isEmpty || name == user.subject) return null;
  // Tokens often carry only the email; an address is never a greeting.
  if (name.contains('@')) return null;
  if (_placeholders.contains(name.toLowerCase())) return null;
  return name;
}

/// A Perfil header's name: the first real one, else the masked phone, else "Tu perfil"; never an ID.
String profileHeaderName({
  required List<String?> names,
  required String phone,
}) {
  for (final name in names) {
    if (name != null && name.trim().isNotEmpty) return name.trim();
  }
  final masked = maskedMobile(phone);
  return masked.isEmpty ? 'Tu perfil' : masked;
}

/// The requester's name: the one just typed, else the saved profile's first word, else the account's.
String? requesterGreetingName(
  AuthenticatedUser? user,
  OnboardingFlow flow, {
  String profileName = '',
}) =>
    switch (flow) {
      OnboardingBrowsing(:final name) when name.trim().isNotEmpty =>
        name.trim(),
      _ => null,
    } ??
    _firstWord(profileName) ??
    greetingName(user);

String? _firstWord(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? null : trimmed.split(RegExp(r'\s+')).first;
}

/// The professional's first name from their profile, or null when blank.
String? greetingFirstName(ProviderProfile? profile) {
  final name = profile?.firstName.trim() ?? '';
  return name.isEmpty ? null : name;
}

/// The greeting name: the onboarding's, else the profile's, else the account's.
String? resolveGreetingName(
  AuthenticatedUser? user,
  ProviderProfile? profile, {
  String onboardingName = '',
}) =>
    (onboardingName.trim().isEmpty ? null : onboardingName.trim()) ??
    greetingFirstName(profile) ??
    greetingName(user);

/// The profile photo, only when greeting the profile's own [name].
String? greetingPhoto(ProviderProfile? profile, {required String name}) {
  if (greetingFirstName(profile) != name) return null;
  final url = profile?.party.photoUrl ?? '';
  return url.isEmpty ? null : url;
}
