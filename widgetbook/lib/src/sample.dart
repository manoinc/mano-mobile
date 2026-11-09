import 'package:flutter/widgets.dart';
import 'package:mano_ui/mano_ui.dart';
import 'package:widgetbook/widgetbook.dart';

// Sample content shared by the use cases, in the app's own Spanish.
const samplePhoto = 'https://randomuser.me/api/portraits/women/44.jpg';
const sampleProPhoto = 'https://randomuser.me/api/portraits/men/32.jpg';
const sampleListingPhoto =
    'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800';

void noop() {}

/// One component with its use cases.
WidgetbookComponent component(
  String name,
  Map<String, WidgetBuilder> useCases,
) => WidgetbookComponent(
  name: name,
  useCases: [
    for (final MapEntry(:key, :value) in useCases.entries)
      WidgetbookUseCase(name: key, builder: value),
  ],
);

const sampleCaptureTips = [
  ManoTip('Limpia el lente de tu cámara', emphasis: 'Limpia el lente'),
  ManoTip(
    'Pon la cédula sobre una superficie plana y oscura',
    emphasis: 'superficie plana y oscura',
  ),
  ManoTip(
    'Evita reflejos y sombras sobre los datos',
    emphasis: 'Evita reflejos',
  ),
];
