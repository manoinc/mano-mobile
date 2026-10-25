import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

Future<DataFailure> _failureOf(Object error) async {
  final result = await guardGateway<int>(() async => throw error);
  return (result as Err<int, DataFailure>).failure;
}

void main() {
  test('passes the value through', () async {
    final result = await guardGateway(() async => 7);

    expect(result, isA<Ok<int, DataFailure>>());
    expect((result as Ok<int, DataFailure>).value, 7);
  });

  test('a NotFound rejection is DataNotFound', () async {
    expect(
      await _failureOf(const GatewayRejected('NotFound: no such job')),
      isA<DataNotFound>(),
    );
  });

  for (final message in [
    'PermissionDenied: not yours',
    'FailedPrecondition: job already started',
    'InvalidArgument: amount must be >= 0',
    'AlreadyExists: you already quoted',
    'workerId must be a UUID',
  ]) {
    test('"$message" is DataRejected with the message', () async {
      final failure = await _failureOf(GatewayRejected(message));

      expect(failure, isA<DataRejected>());
      expect((failure as DataRejected).reason, message);
    });
  }

  test('an Unavailable rejection is DataUnavailable', () async {
    expect(
      await _failureOf(const GatewayRejected('Unavailable: scheduler down')),
      isA<DataUnavailable>(),
    );
  });

  test('an unreachable gateway is DataUnavailable', () async {
    final failure = await _failureOf(const GatewayUnavailable('refused'));

    expect(failure, isA<DataUnavailable>());
    expect((failure as DataUnavailable).detail, 'refused');
  });

  test('an unauthorized call is rethrown for the session to handle', () {
    expect(
      guardGateway(() async => throw const GatewayUnauthorized('expired')),
      throwsA(isA<GatewayUnauthorized>()),
    );
  });

  test('other errors are rethrown', () {
    expect(
      guardGateway(() async => throw StateError('bug')),
      throwsA(isA<StateError>()),
    );
  });
}
