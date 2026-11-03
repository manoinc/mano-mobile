import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

void main() {
  test('keeps finished and cancelled jobs, newest first', () async {
    final now = DateTime(2026, 10, 4, 12);
    final container = ProviderContainer.test(
      overrides: [
        jobRepositoryProvider.overrideWithValue(
          MockJobRepository(now: () => now),
        ),
      ],
    );
    final all = await container.read(myJobsProvider.future);
    final history = await container.read(orderHistoryProvider.future);

    expect(history, isNotEmpty);
    expect(
      history.every(
        (j) =>
            j.status == JobStatus.finished || j.status == JobStatus.cancelled,
      ),
      isTrue,
    );
    expect(
      history.length,
      all
          .where(
            (j) =>
                j.status == JobStatus.finished ||
                j.status == JobStatus.cancelled,
          )
          .length,
    );
    for (var i = 1; i < history.length; i++) {
      expect(history[i - 1].start.isBefore(history[i].start), isFalse);
    }
  });
}
