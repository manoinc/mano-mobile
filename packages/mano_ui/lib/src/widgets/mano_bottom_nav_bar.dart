import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';

/// One of the four ordinary destinations on [ManoBottomNavBar].
///
/// Just an icon and a label -- the bar decides colour and position, and the
/// screen decides what the tap means.
@immutable
class ManoNavItem {
  const ManoNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// The app's 5-slot bottom bar: four destinations either side of a raised
/// CREATE action.
///
/// The centre action is not one of [items] and never touches [currentIndex]
/// -- it starts a flow rather than navigating to a tab, which is why it gets
/// its own callback instead of a fifth index.
class ManoBottomNavBar extends StatelessWidget {
  const ManoBottomNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.onActionTap,
    super.key,
  });

  /// Exactly 4 items: the two either side of the center action button.
  final List<ManoNavItem> items;

  /// Index into [items] (0..3) -- NOT an index into a 5-slot row. The center
  /// action button is not one of [items] and never affects this index.
  final int currentIndex;
  final ValueChanged<int> onTap;
  /// The raised centre action; omitted, the four items spread evenly.
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _sideItem(context, 0)),
              Expanded(child: _sideItem(context, 1)),
              if (onActionTap != null) _ActionButton(onTap: onActionTap!),
              Expanded(child: _sideItem(context, 2)),
              Expanded(child: _sideItem(context, 3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sideItem(BuildContext context, int index) {
    final item = items[index];
    final selected = index == currentIndex;
    final color = selected ? ManoColors.flame : ManoColors.faint;

    return _TappableNavItem(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: color),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// A side item's hit area: a ripple that spreads and fades like a drop
/// landing on still water, plus a brief wiggle on the icon -- rather than the
/// platform's own ink splash, which reads as a hard-edged square once it hits
/// the narrow column each item sits in.
class _TappableNavItem extends StatefulWidget {
  const _TappableNavItem({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_TappableNavItem> createState() => _TappableNavItemState();
}

class _TappableNavItemState extends State<_TappableNavItem>
    with TickerProviderStateMixin {
  bool _down = false;

  late final AnimationController _rippleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  late final AnimationController _wiggleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  /// A small tilt one way, a smaller one back, then level -- big enough to
  /// read as a wiggle, small enough to stay a detail rather than a gesture.
  late final Animation<double> _wiggle =
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0, end: -0.12), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.08), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 0.08, end: 0), weight: 1),
      ]).animate(CurvedAnimation(parent: _wiggleController, curve: Curves.easeOut));

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  void _handleTap() {
    _rippleController.forward(from: 0);
    _wiggleController.forward(from: 0);
    widget.onTap();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _wiggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: ManoMotion.quick,
          curve: ManoMotion.entrance,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ManoSpacing.sm),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                AnimatedBuilder(
                  animation: _rippleController,
                  builder: (context, _) {
                    final t = _rippleController.value;
                    if (t <= 0 || t >= 1) return const SizedBox.shrink();
                    final eased = Curves.easeOut.transform(t);
                    final diameter = 12 + eased * 44;
                    return Opacity(
                      opacity: (1 - t).clamp(0.0, 1.0),
                      child: Container(
                        key: const Key('mano-nav-item-ripple'),
                        width: diameter,
                        height: diameter,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ManoColors.flame.withValues(alpha: 0.18),
                        ),
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _wiggle,
                  builder: (context, child) =>
                      Transform.rotate(angle: _wiggle.value, child: child),
                  child: widget.child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The raised CREATE action at the centre of the bar.
///
/// Flame is spent once per screen; this is the nav bar's use of it, which is
/// why it -- alone of the five slots -- gets the brand's hot colour.
class _ActionButton extends StatefulWidget {
  const _ActionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  static const double _diameter = 56;

  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -12),
      child: Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: ManoMotion.quick,
          curve: ManoMotion.entrance,
          child: Material(
            color: ManoColors.flame,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onTap,
              child: const SizedBox(
                width: _diameter,
                height: _diameter,
                child: Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
