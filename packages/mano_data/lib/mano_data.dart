/// Adapters: the concrete implementations of the ports `mano_domain` declares.
///
/// Everything that knows about a protocol, a plugin or a wire format lives
/// here — the keystore, HTTP, GraphQL. The domain above knows none of it, and
/// the dependency arrow points one way only.
///
/// There is no [SessionRepository] implementation here yet. Which auth
/// provider Mano signs users in through is still an open decision, so nothing
/// has been built that would need unbuilding when it is made — that is the
/// whole point of the port living in `mano_domain` and nowhere else. Whatever
/// adapter comes next arrives as a new file in `src/session/`, an export
/// here, and one override in `mano_session`; nothing above this package
/// changes.
///
/// Each adapter takes its collaborators as interfaces through its constructor,
/// so the pieces that would otherwise demand a device — platform channels,
/// sockets — can be replaced with fakes in an ordinary test.
library;

export 'src/config/mano_config.dart';
export 'src/gateway/gateway_client.dart';
export 'src/session/token_store.dart';
