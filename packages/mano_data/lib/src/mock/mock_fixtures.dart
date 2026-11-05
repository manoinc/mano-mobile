import 'package:mano_domain/mano_domain.dart';

// Shared by the mock adapters so both apps tell one consistent story.
const mockClient = Party(
  id: 'client-1',
  displayName: 'Laura Pérez',
  photoUrl: 'https://randomuser.me/api/portraits/women/68.jpg',
);

/// What a bought lead unlocks offline.
const mockClientContact = ContactInfo(
  phone: '300 123 4567',
  email: 'laura.perez@mano.test',
);

const mockClients = [
  mockClient,
  Party(
    id: 'client-2',
    displayName: 'Camilo Restrepo',
    photoUrl: 'https://randomuser.me/api/portraits/men/45.jpg',
  ),
  Party(
    id: 'client-3',
    displayName: 'Valentina Ospina',
    photoUrl: 'https://randomuser.me/api/portraits/women/26.jpg',
  ),
  Party(
    id: 'client-4',
    displayName: 'Sebastián Gómez',
    photoUrl: 'https://randomuser.me/api/portraits/men/22.jpg',
  ),
  Party(
    id: 'client-5',
    displayName: 'Mariana Torres',
    photoUrl: 'https://randomuser.me/api/portraits/women/90.jpg',
  ),
];

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
    jobServiceId: '11111111-0000-0000-0000-000000000001',
    offerantId: 'provider-1',
    rateType: RateType.fixed,
    amountCop: 120000,
    zone: 'Chapinero',
    status: OfferStatus.active,
  ),
  ServiceOffer(
    id: 'offer-2',
    jobServiceId: '11111111-0000-0000-0000-000000000003',
    offerantId: 'provider-2',
    rateType: RateType.hourly,
    amountCop: 45000,
    zone: 'Usaquén',
    status: OfferStatus.active,
  ),
  ServiceOffer(
    id: 'offer-3',
    jobServiceId: '11111111-0000-0000-0000-000000000007',
    offerantId: 'provider-1',
    rateType: RateType.hourly,
    amountCop: 38000,
    zone: '',
    status: OfferStatus.paused,
  ),
];

// Ids match tools/dev/seed_catalog.sql so a live gateway resolves the same titles.
const mockServiceTitles = {
  '11111111-0000-0000-0000-000000000001': 'Limpieza profunda del hogar',
  '11111111-0000-0000-0000-000000000003': 'Reparación de fugas',
  '11111111-0000-0000-0000-000000000007': 'Pintura de interiores',
};

ServiceOffer mockOfferById(String id) =>
    mockOffers.firstWhere((o) => o.id == id, orElse: () => mockOffers.first);

Party mockProviderFor(ServiceOffer offer) => mockProviders.firstWhere(
  (p) => p.id == offer.offerantId,
  orElse: () => mockProviders.first,
);

String mockTitleFor(ServiceOffer offer) =>
    mockServiceTitles[offer.jobServiceId] ?? 'Servicio';

// Job photos; every URL answers 200 on Unsplash.
String mockPhoto(String id) =>
    'https://images.unsplash.com/photo-$id?w=600&h=400&fit=crop';
