import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

const _named = Party(id: 'c1', displayName: 'Laura', photoUrl: '');
const _blank = Party(id: 'p1', displayName: '', photoUrl: '');

const _offer = ServiceOffer(
  id: 'o1',
  jobServiceId: 's1',
  offerantId: 'p1',
  rateType: RateType.fixed,
  amountCop: 1,
  zone: '',
  status: OfferStatus.active,
);

Job _job(Party client, Party provider) => Job(
  id: 'j1',
  offerId: 'o1',
  serviceTitle: '',
  client: client,
  provider: provider,
  rateType: RateType.fixed,
  amountCop: 1,
  start: DateTime(2030),
  status: JobStatus.scheduled,
);

ServiceRequest _request(Party client, Party provider) => ServiceRequest(
  id: 'r1',
  offer: _offer,
  serviceTitle: '',
  client: client,
  provider: provider,
  message: '',
  status: ServiceRequestStatus.pending,
  createdAt: DateTime(2030),
);

void main() {
  test('a job names its parties, or says Cliente and Profesional', () {
    expect(_job(_named, _named).clientName, 'Laura');
    expect(_job(_named, _named).providerName, 'Laura');
    expect(_job(_blank, _blank).clientName, 'Cliente');
    expect(_job(_blank, _blank).providerName, 'Profesional');
  });

  test('a request names its parties, or says Cliente and Profesional', () {
    expect(_request(_named, _named).clientName, 'Laura');
    expect(_request(_blank, _blank).clientName, 'Cliente');
    expect(_request(_blank, _blank).providerName, 'Profesional');
  });

  test('a named party reads name over role; a nameless one, the role once', () {
    expect(partyLine(_named, role: 'Cliente'), (
      title: 'Laura',
      role: 'Cliente',
    ));
    expect(partyLine(_blank, role: 'Tu profesional'), (
      title: 'Tu profesional',
      role: null,
    ));
    expect(
      partyLine(
        const Party(id: 'x', displayName: '  ', photoUrl: ''),
        role: 'Cliente',
      ),
      (title: 'Cliente', role: null),
    );
  });
}
