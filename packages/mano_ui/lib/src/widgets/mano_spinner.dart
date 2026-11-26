import 'package:flutter/material.dart';

/// A small inline spinner for busy buttons and uploads; screens use skeletons.
class ManoSpinner extends StatelessWidget {
  const ManoSpinner({this.size = 18, this.color, super.key});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      color: color,
      semanticsLabel: 'Cargando',
    ),
  );
}
