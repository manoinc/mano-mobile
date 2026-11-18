import 'package:mano_session/mano_session.dart';

/// Services and keys come from `config/dev.json`, `config/prod.json` or a personal `.env`, via `--dart-define-from-file`.
final ManoConfig requesterConfig = ManoConfig.fromEnv(
  manoEnvironment,
  appRole: ManoRole.requester,
);

/// Shown in Configuración; test/version_test.dart keeps it equal to `version` in pubspec.yaml.
const String requesterAppVersion = '1.0.0';
