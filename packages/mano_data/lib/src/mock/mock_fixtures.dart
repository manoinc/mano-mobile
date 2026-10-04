import 'package:mano_domain/mano_domain.dart';

// Shared by the mock adapters so both apps tell one consistent story.
const mockClient = Party(
  id: 'client-1',
  displayName: 'Laura Pérez',
  photoUrl: 'https://randomuser.me/api/portraits/women/68.jpg',
);

const mockProviders = [
  Party(
    id: 'provider-1',
    displayName: 'Andrés Castro',
    photoUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
  ),
  Party(
    id: 'provider-2',
    displayName: 'Ana Gómez',
    photoUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
  ),
];

const mockOffers = [
  ServiceOffer(
    id: 'offer-1',
    jobServiceId: 'service-cleaning',
    offerantId: 'provider-1',
    rateType: RateType.fixed,
    amountCop: 120000,
    zone: 'Chapinero',
    status: OfferStatus.active,
  ),
  ServiceOffer(
    id: 'offer-2',
    jobServiceId: 'service-plumbing',
    offerantId: 'provider-2',
    rateType: RateType.hourly,
    amountCop: 45000,
    zone: 'Usaquén',
    status: OfferStatus.active,
  ),
  ServiceOffer(
    id: 'offer-3',
    jobServiceId: 'service-painting',
    offerantId: 'provider-1',
    rateType: RateType.hourly,
    amountCop: 38000,
    zone: '',
    status: OfferStatus.paused,
  ),
];

const mockServiceTitles = {
  'service-cleaning': 'Limpieza profunda',
  'service-plumbing': 'Reparación de fugas',
  'service-painting': 'Pintura de interiores',
};

ServiceOffer mockOfferById(String id) =>
    mockOffers.firstWhere((o) => o.id == id, orElse: () => mockOffers.first);

Party mockProviderFor(ServiceOffer offer) => mockProviders.firstWhere(
  (p) => p.id == offer.offerantId,
  orElse: () => mockProviders.first,
);

String mockTitleFor(ServiceOffer offer) =>
    mockServiceTitles[offer.jobServiceId] ?? 'Servicio';
