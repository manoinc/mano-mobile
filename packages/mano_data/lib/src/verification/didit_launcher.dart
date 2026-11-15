/// How Didit's native flow ended, as far as the app can tell.
enum DiditOutcome { finished, cancelled, failed }

/// Opens Didit's native SDK on a session; the app supplies the real one.
abstract interface class DiditLauncher {
  Future<DiditOutcome> start(String sessionToken);
}
