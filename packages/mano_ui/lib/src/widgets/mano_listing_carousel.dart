import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A height-bounded horizontal strip that snaps one card at a time.
///
/// Each child takes `viewportFraction` of the width, so the next one peeks in.
class ManoListingCarousel extends StatefulWidget {
  const ManoListingCarousel({
    required this.children,
    required this.height,
    this.viewportFraction = 0.8,
    super.key,
  });

  final List<Widget> children;
  final double height;
  final double viewportFraction;

  @override
  State<ManoListingCarousel> createState() => _ManoListingCarouselState();
}

class _ManoListingCarouselState extends State<ManoListingCarousel> {
  late final PageController _controller = PageController(
    viewportFraction: widget.viewportFraction,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _controller,
        padEnds: false,
        itemCount: widget.children.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: ManoSpacing.sm),
          child: widget.children[index],
        ),
      ),
    );
  }
}
