/// Adapters: the concrete implementations of the ports `mano_domain` declares.
///
/// Everything that knows about a protocol, a plugin or a wire format lives
/// here — OAuth, the keystore, HTTP, GraphQL. The domain above knows none of
/// it, and the dependency arrow points one way only.
///
/// Each adapter takes its collaborators as interfaces through its constructor,
/// so the pieces that would otherwise demand a device — platform channels,
/// sockets — can be replaced with fakes in an ordinary test.
library;

export 'src/config/mano_config.dart';
export 'src/gateway/gateway_client.dart';
export 'src/session/app_auth_oidc_client.dart';
export 'src/session/oidc_client.dart';
export 'src/session/oidc_session_repository.dart';
export 'src/session/token_store.dart';
