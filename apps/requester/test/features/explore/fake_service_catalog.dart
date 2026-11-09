import 'dart:async';

import 'package:mano_session/mano_session.dart';

/// An in-memory catalog that filters like the gateway: exact category, substring text.
class FakeServiceCatalog implements ServiceCatalog {
  FakeServiceCatalog({this.services = defaultServices});

  static const defaultServices = [
    JobService(
      id: 's1',
      category: 'cleaning',
      title: 'Limpieza profunda',
      description: 'Cocina, baños y habitaciones de arriba a abajo.',
    ),
    JobService(
      id: 's2',
      category: 'plumbing',
      title: 'Reparación de fugas',
      description: 'Arreglamos llaves, tuberías y sifones.',
    ),
  ];

  List<JobService> services;
  Object? searchError;

  // Set to hold searches in flight until the test completes it.
  Completer<void>? hold;
  final searches = <({String? category, String? text})>[];

  @override
  Future<List<JobService>> search({String? category, String? text}) async {
    searches.add((category: category, text: text));
    await hold?.future;
    final error = searchError;
    if (error != null) throw error;
    return [
      for (final s in services)
        if ((category == null || s.category == category) &&
            (text == null ||
                s.title.toLowerCase().contains(text.toLowerCase())))
          s,
    ];
  }

  @override
  Future<JobService?> service(String id) async {
    for (final s in services) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Future<ServiceOffer?> offer(String id) async => null;

  @override
  Future<List<ServiceOffer>> offersFor(String jobServiceId) async => [];
}
