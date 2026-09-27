import 'package:flutter/material.dart';

/// Google's mark, for the sign-in button.
///
/// PLACEHOLDER: `assets/brand/google-g.png` is a neutral stand-in, not
/// Google's four-colour G. Drop the official file from Google's identity
/// guidelines over it; nothing else has to change.
class GoogleMark extends StatelessWidget {
  const GoogleMark({this.size = 20, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/google-g.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
  }
}
