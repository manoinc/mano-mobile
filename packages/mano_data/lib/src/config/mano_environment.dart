/// The dart-defines compiled in from `config/*.json` and an optional `.env` (`--dart-define-from-file`).
const Map<String, String> manoEnvironment = {
  'MANO_GATEWAY': String.fromEnvironment('MANO_GATEWAY'),
  'SUPERTOKENS_API_DOMAIN': String.fromEnvironment('SUPERTOKENS_API_DOMAIN'),
  'GOOGLE_SERVER_CLIENT_ID': String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
  'MANO_INVITE_LINK_BASE': String.fromEnvironment('MANO_INVITE_LINK_BASE'),
  'MANO_APPROVE_IDENTITY': String.fromEnvironment('MANO_APPROVE_IDENTITY'),
};
