/// A bank a payout can go to, by its ACH Colombia code.
final class ColombianBank {
  const ColombianBank({required this.code, required this.name});

  final String code;
  final String name;
}

/// The major Colombian banks; codes to confirm against mano-billing / Wompi.
abstract final class ColombianBanks {
  static const all = <ColombianBank>[
    ColombianBank(code: '1007', name: 'Bancolombia'),
    ColombianBank(code: '1051', name: 'Davivienda'),
    ColombianBank(code: '1001', name: 'Banco de Bogotá'),
    ColombianBank(code: '1013', name: 'BBVA Colombia'),
    ColombianBank(code: '1023', name: 'Banco de Occidente'),
    ColombianBank(code: '1002', name: 'Banco Popular'),
    ColombianBank(code: '1052', name: 'Banco AV Villas'),
    ColombianBank(code: '1032', name: 'Banco Caja Social'),
    ColombianBank(code: '1019', name: 'Scotiabank Colpatria'),
    ColombianBank(code: '1006', name: 'Itaú'),
    ColombianBank(code: '1040', name: 'Banco Agrario'),
    ColombianBank(code: '1012', name: 'Banco GNB Sudameris'),
    ColombianBank(code: '1062', name: 'Banco Falabella'),
    ColombianBank(code: '1060', name: 'Banco Pichincha'),
    ColombianBank(code: '1070', name: 'Lulo Bank'),
  ];

  static ColombianBank? byCode(String code) {
    for (final bank in all) {
      if (bank.code == code) return bank;
    }
    return null;
  }
}
