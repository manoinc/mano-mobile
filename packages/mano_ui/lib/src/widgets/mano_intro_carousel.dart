import 'package:flutter/material.dart';

import '../brand/mano_opening.dart';
import '../brand/mano_wordmark.dart';
import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';
import 'mano_page_indicator.dart';
import 'mano_text_action.dart';

/// The pre-sign-in carousel: wordmark, skip and indicator on top, slides with parallax, a sticky bar.
class ManoIntroCarousel extends StatefulWidget {
  const ManoIntroCarousel({
    required this.count,
    required this.slideBuilder,
    required this.bottomBarBuilder,
    required this.onSkip,
    this.skipLabel = 'Omitir',
    this.index = 0,
    this.onPageChanged,
    super.key,
  });

  final int count;

  /// Builds slide [index]; `reveal` runs 0 to 1 once, for a staggered arrival.
  final Widget Function(BuildContext context, int index, double reveal)
  slideBuilder;

  /// Builds the sticky bar for the slide in view; `next` pages forward.
  final Widget Function(BuildContext context, int index, VoidCallback next)
  bottomBarBuilder;

  final VoidCallback onSkip;
  final String skipLabel;

  /// The page to show; changing it from outside animates there.
  final int index;
  final ValueChanged<int>? onPageChanged;

  @override
  State<ManoIntroCarousel> createState() => _ManoIntroCarouselState();
}

class _ManoIntroCarouselState extends State<ManoIntroCarousel>
    with SingleTickerProviderStateMixin {
  late final PageController _pages = PageController(initialPage: widget.index);

  /// Fractional page position, for the parallax. Safe before first layout.
  double _offset = 0;

  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: ManoMotion.sheet,
  );

  bool _revealStarted = false;

  @override
  void initState() {
    super.initState();
    _offset = widget.index.toDouble();
    _pages.addListener(_trackOffset);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The rows arrive once, the first time the slide is built.
    if (_revealStarted) return;
    _revealStarted = true;
    if (_still) {
      _reveal.value = 1;
    } else {
      _reveal.forward();
    }
  }

  @override
  void didUpdateWidget(ManoIntroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The flow moved the slide from outside -- back() from registration, say.
    if (widget.index != oldWidget.index && _pages.hasClients) {
      final current = (_pages.page ?? _offset).round();
      if (current != widget.index) _animateTo(widget.index);
    }
  }

  @override
  void dispose() {
    _pages.removeListener(_trackOffset);
    _pages.dispose();
    _reveal.dispose();
    super.dispose();
  }

  void _trackOffset() {
    if (!_pages.hasClients) return;
    setState(() => _offset = _pages.page ?? _offset);
  }

  void _animateTo(int index) {
    if (_still) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(
        index,
        duration: ManoMotion.normal,
        curve: ManoMotion.entrance,
      );
    }
  }

  bool get _still => MediaQuery.disableAnimationsOf(context);

  @override
  Widget build(BuildContext context) {
    final index = _offset.round().clamp(0, widget.count - 1);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              count: widget.count,
              index: index,
              skipLabel: widget.skipLabel,
              onSkip: widget.onSkip,
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: widget.onPageChanged,
                children: [
                  for (var i = 0; i < widget.count; i++)
                    _Parallax(
                      delta: _offset - i,
                      still: _still,
                      child: AnimatedBuilder(
                        animation: _reveal,
                        builder: (context, _) =>
                            widget.slideBuilder(context, i, _reveal.value),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ManoSpacing.lg,
                vertical: ManoSpacing.md,
              ),
              child: widget.bottomBarBuilder(
                context,
                index,
                () => _animateTo((index + 1).clamp(0, widget.count - 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Drifts a slide's content against the page, which is what reads as depth.
class _Parallax extends StatelessWidget {
  const _Parallax({
    required this.delta,
    required this.still,
    required this.child,
  });

  final double delta;
  final bool still;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (still) return child;

    final width = MediaQuery.sizeOf(context).width;
    return Opacity(
      opacity: (1 - delta.abs()).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(-delta * width * 0.25, 0),
        child: child,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.count,
    required this.index,
    required this.skipLabel,
    required this.onSkip,
  });

  final int count;
  final int index;
  final String skipLabel;
  final VoidCallback onSkip;

  /// The wordmark's band, plus room for the indicator beneath it.
  static const double _height =
      ManoLockup.inset + ManoLockup.restingHeight + ManoSpacing.lg;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: Stack(
        children: [
          // Exactly where ManoOpening flies its own copy. Centre the indicator
          // on this row instead and the two collide on a narrow phone.
          const Positioned(
            left: ManoLockup.inset,
            top: ManoLockup.inset,
            child: ManoWordmark(
              height: ManoLockup.restingHeight,
              color: ManoColors.flame,
            ),
          ),
          Positioned(
            right: ManoSpacing.sm,
            top: ManoLockup.inset + (ManoLockup.restingHeight - 44) / 2,
            child: ManoTextAction(label: skipLabel, onPressed: onSkip),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: ManoPageIndicator(count: count, index: index),
            ),
          ),
        ],
      ),
    );
  }
}
