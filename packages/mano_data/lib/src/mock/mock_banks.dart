import 'package:mano_domain/mano_domain.dart';

/// The major Colombian banks by ACH code, for offline mode; live lists come from billing.
const mockBanks = <Bank>[
  Bank(code: '1007', name: 'Bancolombia'),
  Bank(code: '1051', name: 'Davivienda'),
  Bank(code: '1001', name: 'Banco de Bogotá'),
  Bank(code: '1013', name: 'BBVA Colombia'),
  Bank(code: '1023', name: 'Banco de Occidente'),
  Bank(code: '1002', name: 'Banco Popular'),
  Bank(code: '1052', name: 'Banco AV Villas'),
  Bank(code: '1032', name: 'Banco Caja Social'),
  Bank(code: '1019', name: 'Scotiabank Colpatria'),
  Bank(code: '1006', name: 'Itaú'),
  Bank(code: '1040', name: 'Banco Agrario'),
  Bank(code: '1012', name: 'Banco GNB Sudameris'),
  Bank(code: '1062', name: 'Banco Falabella'),
  Bank(code: '1060', name: 'Banco Pichincha'),
  Bank(code: '1070', name: 'Lulo Bank'),
];
