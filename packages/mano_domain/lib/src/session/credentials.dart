/// What a person types to sign in or sign up.
final class Credentials {
  Credentials({required String email, required this.password})
    : email = email.trim().toLowerCase();

  final String email;
  final String password;

  // Omits the password: credentials end up in logs and error reports.
  @override
  String toString() => 'Credentials(email: $email)';
}
