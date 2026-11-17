import 'package:mano_session/mano_session.dart';

/// Services and keys come from `config/dev.json`, `config/prod.json` or a personal `.env`, via `--dart-define-from-file`.
final ManoConfig requesterConfig = ManoConfig.fromEnv(
  manoEnvironment,
  appRole: ManoRole.requester,
);

/// Shown in Configuración; keep in step with `version` in pubspec.yaml.
const String requesterAppVersion = String.fromEnvironment(
  'MANO_APP_VERSION',
  defaultValue: '0.1.0',
);
