/// The realm roles Mano assigns meaning to.
///
/// Names come from the project's ubiquitous language: a Solicitante
/// (`requester`) asks for work and a Proveedor (`provider`) performs it. They
/// are the same strings the Rust backend reads, whatever identity provider
/// ends up issuing them — so all ends of the stack agree on one vocabulary.
abstract final class ManoRole {
  /// Solicitante: asks for domestic work to be done.
  static const String requester = 'requester';

  /// Proveedor: performs the work.
  static const String provider = 'provider';
}

/// The verified identity of whoever is using the app.
///
/// This mirrors `Principal` in `libmano-backapp` field for field, deliberately.
/// The backend is the only party that can decide these values — it holds the
/// realm's public keys and the app does not — so the app treats them as
/// received facts rather than something it derives from a token itself.
final class AuthenticatedUser {
  const AuthenticatedUser({
    required this.subject,
    required this.roles,
    this.username,
    this.email,
  });

  /// Immutable identity assigned by the authentication system (`sub`).
  /// Stable across username changes, and the only safe key for storing
  /// anything against this person.
  final String subject;

  /// The caller's handle, when the provider reports one.
  final String? username;

  /// The caller's email address, when reported.
  final String? email;

  /// Roles granted to this user, realm and client roles merged.
  ///
  /// Treat these as authorization *input*, not as a decision: what a role
  /// permits is application policy. The backend re-checks every request
  /// regardless, so hiding a button here is a courtesy to the user, never a
  /// security measure.
  final Set<String> roles;

  /// Whether this user was granted [role]. Matching is case-sensitive,
  /// because role names are.
  bool hasRole(String role) => roles.contains(role);

  /// Whether this user was granted at least one of [candidates].
  /// An empty collection is never satisfied.
  bool hasAnyRole(Iterable<String> candidates) => candidates.any(hasRole);

  /// Whether this user was granted every one of [candidates].
  /// An empty collection is always satisfied.
  bool hasAllRoles(Iterable<String> candidates) => candidates.every(hasRole);

  /// Whether this user may ask for work to be done.
  bool get isRequester => hasRole(ManoRole.requester);

  /// Whether this user may perform work.
  bool get isProvider => hasRole(ManoRole.provider);

  /// The handle to show, falling back to something always present.
  String get displayName => username ?? email ?? subject;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthenticatedUser &&
          subject == other.subject &&
          username == other.username &&
          email == other.email &&
          _setEquals(roles, other.roles);

  @override
  int get hashCode =>
      Object.hash(subject, username, email, Object.hashAllUnordered(roles));

  @override
  String toString() =>
      'AuthenticatedUser(subject: $subject, username: $username, '
      'roles: $roles)';
}

bool _setEquals(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
