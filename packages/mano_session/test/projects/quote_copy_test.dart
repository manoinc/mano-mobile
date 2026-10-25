import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

Quote _quote(Party worker, QuoteStatus status) => Quote(
  id: 'q',
  projectId: 'p',
  projectTitle: 'Pintar',
  worker: worker,
  amountCop: 1,
  status: status,
  createdAt: DateTime(2026),
);

const _named = Party(id: 'w1', displayName: 'Jorge Peña', photoUrl: '');
const _blank = Party(id: 'w2', displayName: '', photoUrl: '');

void main() {
  test('a quote names its worker, or says Profesional', () {
    expect(_quote(_named, QuoteStatus.submitted).workerName, 'Jorge Peña');
    expect(_quote(_blank, QuoteStatus.submitted).workerName, 'Profesional');
  });

  test('each quote status has its Spanish label', () {
    expect(_quote(_blank, QuoteStatus.submitted).statusLabel, 'Enviada');
    expect(_quote(_blank, QuoteStatus.selected).statusLabel, 'Elegida');
    expect(_quote(_blank, QuoteStatus.discarded).statusLabel, 'No elegida');
  });

  test('initials come from the name, the placeholder included', () {
    expect(_quote(_named, QuoteStatus.submitted).workerInitials, 'JP');
    expect(_quote(_blank, QuoteStatus.submitted).workerInitials, 'P');
  });

  test('a closed project is told apart from other refusals', () {
    expect(
      const DataRejected(reason: 'FailedPrecondition: not open')
          .isClosedForQuotes,
      isTrue,
    );
    expect(
      const DataRejected(reason: 'AlreadyExists: one').isClosedForQuotes,
      isFalse,
    );
    expect(const DataUnavailable().isClosedForQuotes, isFalse);
  });
}
