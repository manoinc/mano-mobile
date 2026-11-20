import 'package:mano_session/mano_session.dart';

/// Services and keys come from `config/dev.json`, `config/prod.json` or a personal `.env`, via `--dart-define-from-file`.
final ManoConfig providerConfig = ManoConfig.fromEnv(
  manoEnvironment,
  appRole: ManoRole.provider,
);
