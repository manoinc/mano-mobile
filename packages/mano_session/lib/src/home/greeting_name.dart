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
