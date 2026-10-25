import 'package:mano_domain/mano_domain.dart';

import '../mock/mock_fixtures.dart';

// Providers who quote but are not the signed-in one.
const _jorge = Party(
  id: 'provider-3',
  displayName: 'Jorge Peña',
  photoUrl: 'https://randomuser.me/api/portraits/men/75.jpg',
);
const _camila = Party(
  id: 'provider-4',
  displayName: 'Camila Rodríguez',
  photoUrl: 'https://randomuser.me/api/portraits/women/12.jpg',
);

/// Realistic Colombian projects: some the mock requester owns, some open to quote.
List<({Project project, String ownerId})> mockProjectSeeds(DateTime now) {
  DateTime ago({int days = 0, int hours = 0}) =>
      now.subtract(Duration(days: days, hours: hours));
  final andres = mockProviders[0];
  final ana = mockProviders[1];

  Quote quote(
    String id,
    String projectId,
    String projectTitle,
    Party worker,
    int amount,
    QuoteStatus status,
    DateTime at, [
    String? message,
  ]) => Quote(
    id: id,
    projectId: projectId,
    projectTitle: projectTitle,
    worker: worker,
    amountCop: amount,
    message: message,
    status: status,
    createdAt: at,
  );

  ({Project project, String ownerId}) seed(
    String ownerId,
    String id,
    String category,
    String title,
    String description,
    ProjectStatus status,
    DateTime at, {
    int? budget,
    List<String> photos = const [],
    List<Quote> Function(String id, String title)? quotes,
  }) => (
    ownerId: ownerId,
    project: Project(
      id: id,
      category: category,
      title: title,
      description: description,
      photoUrls: [for (final p in photos) mockPhoto(p)],
      budgetCop: budget,
      status: status,
      createdAt: at,
      quotes: quotes?.call(id, title) ?? const [],
    ),
  );

  final laura = mockClient.id;
  return [
    seed(
      laura,
      'project-1',
      ServiceCategories.painting,
      'Pintar apartamento de 70 m²',
      'Son tres habitaciones, sala-comedor y el pasillo. Las paredes tienen '
          'algunas grietas y una mancha de humedad en el baño. Quiero blanco '
          'hueso mate.',
      ProjectStatus.open,
      ago(hours: 5),
      budget: 1800000,
      photos: ['1595814433015-e6f5ce69614e'],
      quotes: (id, title) => [
        quote(
          'quote-1',
          id,
          title,
          andres,
          1650000,
          QuoteStatus.submitted,
          ago(hours: 4),
          'Incluye resanar grietas, tratar la humedad y dos manos de pintura. '
              'Lo termino en 4 días.',
        ),
        quote(
          'quote-2',
          id,
          title,
          ana,
          1900000,
          QuoteStatus.submitted,
          ago(hours: 3),
          'Pintura Viniltex tipo 1 incluida. Cubro pisos y muebles.',
        ),
        quote(
          'quote-3',
          id,
          title,
          _jorge,
          1450000,
          QuoteStatus.submitted,
          ago(hours: 1),
        ),
      ],
    ),
    seed(
      mockClients[1].id,
      'project-5',
      ServiceCategories.cleaning,
      'Limpieza final de obra',
      'Terminamos de remodelar la cocina y quedó polvo de cemento en todo el '
          'apartamento. Son 80 m² en Laureles.',
      ProjectStatus.open,
      ago(hours: 8),
      budget: 450000,
      photos: ['1581578731548-c64695cc6952'],
    ),
    seed(
      laura,
      'project-2',
      ServiceCategories.plumbing,
      'Cambiar tubería del baño',
      'La tubería del baño principal es galvanizada y ya tiene óxido. Quiero '
          'cambiarla por PVC antes de enchapar.',
      ProjectStatus.open,
      ago(days: 1),
    ),
    seed(
      mockClients[2].id,
      'project-6',
      ServiceCategories.plumbing,
      'Instalar calentador de paso a gas',
      'Ya compré el calentador; necesito la instalación con la salida de gases '
          'y la conexión a la red de gas.',
      ProjectStatus.open,
      ago(days: 1, hours: 6),
    ),
    seed(
      mockClients[4].id,
      'project-8',
      ServiceCategories.electrical,
      'Instalar tomas y luces en el estudio',
      'Necesito dos tomas dobles nuevas y cambiar la lámpara del techo por un '
          'panel LED.',
      ProjectStatus.open,
      ago(days: 2),
      budget: 350000,
      quotes: (id, title) => [
        quote(
          'quote-8',
          id,
          title,
          ana,
          320000,
          QuoteStatus.submitted,
          ago(days: 1),
        ),
      ],
    ),
    seed(
      laura,
      'project-3',
      ServiceCategories.electrical,
      'Cambiar toda la iluminación a LED',
      'Casa de dos pisos, unas 25 lámparas. Quiero luz cálida en las '
          'habitaciones y fría en la cocina.',
      ProjectStatus.awarded,
      ago(days: 3),
      budget: 600000,
      photos: ['1621905251189-08b45d6a269e'],
      quotes: (id, title) => [
        quote(
          'quote-4',
          id,
          title,
          andres,
          580000,
          QuoteStatus.selected,
          ago(days: 3, hours: -2),
          'Incluye los paneles y el cableado que haga falta.',
        ),
        quote(
          'quote-5',
          id,
          title,
          _camila,
          650000,
          QuoteStatus.discarded,
          ago(days: 3, hours: -1),
        ),
        quote(
          'quote-6',
          id,
          title,
          _jorge,
          540000,
          QuoteStatus.submitted,
          ago(days: 2),
          'Solo mano de obra; los bombillos los pone usted.',
        ),
      ],
    ),
    seed(
      mockClients[3].id,
      'project-7',
      ServiceCategories.gardening,
      'Diseño de jardín vertical en el balcón',
      'Balcón de 3 × 2 m con buena luz de la mañana. Quiero plantas fáciles de '
          'cuidar y riego por goteo.',
      ProjectStatus.open,
      ago(days: 4),
      budget: 2500000,
      photos: ['1416879595882-3373a0480b5b'],
    ),
    seed(
      laura,
      'project-4',
      ServiceCategories.gardening,
      'Podar los árboles del antejardín',
      'Dos guayacanes que ya tocan los cables de la luz.',
      ProjectStatus.cancelled,
      ago(days: 9),
    ),
  ];
}
