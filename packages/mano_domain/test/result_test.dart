import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    test('an Ok carries its value and reports success', () {
      const result = Ok<int, String>(7);

      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.valueOrNull, 7);
      expect(result.failureOrNull, isNull);
    });

    test('an Err carries its failure and reports failure', () {
      const result = Err<int, String>('nope');

      expect(result.isOk, isFalse);
      expect(result.isErr, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, 'nope');
    });

    test('a switch over a Result is exhaustive', () {
      // The value of sealing Result: adding a third case would break every
      // switch in the codebase at compile time rather than at runtime.
      String describe(Result<int, String> result) => switch (result) {
        Ok(:final value) => 'ok $value',
        Err(:final failure) => 'err $failure',
      };

      expect(describe(const Ok(1)), 'ok 1');
      expect(describe(const Err('bad')), 'err bad');
    });

    test('map transforms a success and leaves a failure alone', () {
      expect(
        const Ok<int, String>(2).map((v) => v * 10),
        const Ok<int, String>(20),
      );
      expect(
        const Err<int, String>('bad').map((v) => v * 10),
        const Err<int, String>('bad'),
      );
    });

    test('mapFailure translates a failure and leaves a success alone', () {
      // How an adapter converts a transport failure into the vocabulary its
      // port promises.
      expect(
        const Err<int, String>('socket').mapFailure((f) => f.length),
        const Err<int, int>(6),
      );
      expect(
        const Ok<int, String>(2).mapFailure((f) => f.length),
        const Ok<int, int>(2),
      );
    });

    test('andThen chains and short-circuits on the first failure', () {
      Result<int, String> doubleIt(int v) => Ok(v * 2);
      Result<int, String> fail(int _) => const Err('stopped');

      expect(
        const Ok<int, String>(3).andThen(doubleIt),
        const Ok<int, String>(6),
      );
      expect(
        const Ok<int, String>(3).andThen(fail),
        const Err<int, String>('stopped'),
      );
      expect(
        const Err<int, String>('first').andThen(doubleIt),
        const Err<int, String>('first'),
      );
    });

    test('fold collapses both sides', () {
      expect(const Ok<int, String>(4).fold((v) => 'v$v', (f) => 'f$f'), 'v4');
      expect(
        const Err<int, String>('x').fold((v) => 'v$v', (f) => 'f$f'),
        'fx',
      );
    });

    test('equality is by contents, so tests can compare directly', () {
      expect(const Ok<int, String>(1), const Ok<int, String>(1));
      expect(const Err<int, String>('a'), const Err<int, String>('a'));
      expect(const Ok<int, String>(1), isNot(const Ok<int, String>(2)));
    });
  });
}
