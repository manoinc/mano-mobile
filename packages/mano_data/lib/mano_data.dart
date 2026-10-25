/// Adapters: the concrete implementations of the ports `mano_domain` declares.
///
/// Everything that knows about a protocol, a plugin or a wire format lives
/// here — the keystore, HTTP, GraphQL. The domain above knows none of it, and
/// the dependency arrow points one way only.
///
/// Each adapter takes its collaborators as interfaces through its constructor,
/// so the pieces that would otherwise demand a device — platform channels,
/// sockets — can be replaced with fakes in an ordinary test.
library;

export 'src/config/mano_config.dart';
export 'src/catalog/gateway_offer_management.dart';
export 'src/catalog/gateway_service_catalog.dart';
export 'src/gateway/gateway_client.dart';
export 'src/gateway/gateway_failure.dart';
export 'src/gateway/gateway_transport.dart';
export 'src/scheduling/gateway_availability_repository.dart';
export 'src/gateway/subscription_client.dart';
export 'src/messaging/gateway_chat_repository.dart';
export 'src/messaging/gateway_conversation_repository.dart';
export 'src/session/in_memory_session_repository.dart';
export 'src/session/supertokens_session_repository.dart';
export 'src/session/token_store.dart';

// Mock implementations pending real gateway-backed adapters.
export 'src/catalog/mock_catalog_repository.dart';
export 'src/catalog/mock_offer_management.dart';
export 'src/earnings/mock_earnings_repository.dart';
export 'src/jobs/mock_job_repository.dart';
export 'src/profile/mock_provider_profile_repository.dart';
export 'src/messaging/mock_chat_repository.dart';
export 'src/messaging/mock_conversation_repository.dart';
export 'src/onboarding/mock_provider_onboarding_repository.dart';
export 'src/requests/mock_service_request_repository.dart';
export 'src/scheduling/mock_availability_repository.dart';
export 'src/wallet/mock_wallet_repository.dart';
