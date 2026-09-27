import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

/// The composition step for registration, mirroring `sessionRepositoryProvider`.
final registrationRepositoryProvider = Provider<RegistrationRepository>(
  (ref) => const _LocalOnlyRegistration(),
);

/// Stands in until there is somewhere to send a draft.
///
/// Returns [Ok], unlike the auth stub, and the difference is deliberate: a
/// sign-in that cannot reach a provider has genuinely failed, but a draft that
/// was only ever going to be kept on the device has not. The name says so.
final class _LocalOnlyRegistration implements RegistrationRepository {
  const _LocalOnlyRegistration();

  @override
  Future<Result<void, RegistrationFailure>> submit(
    RegistrationDraft draft,
  ) async => const Ok<void, RegistrationFailure>(null);
}
