import 'package:mano_session/mano_session.dart';

/// Services and keys come from `config/dev.json`, `config/prod.json` or a personal `.env`, via `--dart-define-from-file`.
final ManoConfig providerConfig = ManoConfig.fromEnv(
  manoEnvironment,
  appRole: ManoRole.provider,
);

/// Reported with every error; test/version_test.dart keeps it equal to `version` in pubspec.yaml.
const String providerAppVersion = '0.1.0';
