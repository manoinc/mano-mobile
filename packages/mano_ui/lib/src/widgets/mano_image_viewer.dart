import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';

/// One photo full screen on black: pinch to zoom, tap or swipe down to close.
class ManoImageViewer extends StatefulWidget {
  const ManoImageViewer({required this.image, this.heroTag, super.key});

  final ImageProvider image;

  /// Matches the thumbnail's [Hero] so the photo grows out of it.
  final Object? heroTag;

  /// The hero tag for photo [index] of message or gallery [id].
  static Object heroTagFor(String id, int index) => 'mano-photo-$id-$index';

  /// Pushes the viewer above everything, the bottom bar included.
  static Future<void> show(
    BuildContext context, {
    required ImageProvider image,
    Object? heroTag,
  }) => Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: ManoMotion.sheet,
      reverseTransitionDuration: ManoMotion.normal,
      pageBuilder: (context, animation, secondary) =>
          ManoImageViewer(image: image, heroTag: heroTag),
      transitionsBuilder: (context, animation, secondary, child) =>
          FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: ManoMotion.entrance,
              reverseCurve: ManoMotion.exit,
            ),
            child: child,
          ),
    ),
  );

  @override
  State<ManoImageViewer> createState() => _ManoImageViewerState();
}

class _ManoImageViewerState extends State<ManoImageViewer> {
  static const _dismissDistance = 120.0;
  static const _dismissVelocity = 700.0;

  final _zoom = TransformationController();
  var _zoomed = false;
  var _drag = 0.0;
  var _dragging = false;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(_onZoom);
  }

  @override
  void dispose() {
    _zoom
      ..removeListener(_onZoom)
      ..dispose();
    super.dispose();
  }

  void _onZoom() {
    final zoomed = _zoom.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  void _close() => Navigator.of(context).maybePop();

  void _onDragEnd(DragEndDetails details) {
    final fast = (details.primaryVelocity ?? 0).abs() > _dismissVelocity;
    if (fast || _drag.abs() > _dismissDistance) return _close();
    setState(() {
      _dragging = false;
      _drag = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fade = (1 - _drag.abs() / 400).clamp(0.4, 1.0);
    Widget photo = Image(
      image: widget.image,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.broken_image_outlined,
        size: 48,
        color: context.palette.faint,
      ),
    );
    if (widget.heroTag case final tag?) photo = Hero(tag: tag, child: photo);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            key: const Key('mano-image-viewer-ground'),
            color: _drag == 0
                ? Colors.black
                : Colors.black.withValues(alpha: fade),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
            onVerticalDragStart: _zoomed
                ? null
                : (_) => setState(() => _dragging = true),
            onVerticalDragUpdate: _zoomed
                ? null
                : (d) => setState(() => _drag += d.delta.dy),
            onVerticalDragEnd: _zoomed ? null : _onDragEnd,
            child: AnimatedContainer(
              duration: _dragging ? Duration.zero : ManoMotion.normal,
              curve: ManoMotion.entrance,
              transform: Matrix4.translationValues(0, _drag, 0),
              child: InteractiveViewer(
                transformationController: _zoom,
                maxScale: 4,
                panEnabled: _zoomed,
                child: Center(child: photo),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(ManoSpacing.sm),
                child: IconButton(
                  tooltip: 'Cerrar',
                  onPressed: _close,
                  color: Colors.white,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
