import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';

/// What the guide outlines: an ID card lying flat, or a face.
enum ManoCaptureShape { card, face }

/// A camera-style guide for the ink ground: instruction, outline, help pill.
class ManoCaptureFrame extends StatelessWidget {
  const ManoCaptureFrame({
    required this.instruction,
    this.shape = ManoCaptureShape.card,
    this.preview,
    this.helpLabel,
    this.onHelp,
    super.key,
  });

  final String instruction;
  final ManoCaptureShape shape;

  /// The live lens or the photo just taken, clipped to the guide.
  final Widget? preview;

  /// The help pill shows only with both.
  final String? helpLabel;
  final VoidCallback? onHelp;

  // ID-1 cards (the cédula) are 85.6 × 54 mm.
  static const double _cardRatio = 85.6 / 54;
  static const double _faceRatio = 3 / 4;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isCard = shape == ManoCaptureShape.card;
    final OutlinedBorder outline = isCard
        ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ManoRadius.card),
          )
        : const OvalBorder();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ManoColors.sand,
              borderRadius: BorderRadius.circular(ManoRadius.card),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ManoSpacing.md,
                vertical: ManoSpacing.sm,
              ),
              child: Text(
                instruction,
                textAlign: TextAlign.center,
                style: text.titleSmall?.copyWith(color: ManoColors.ink),
              ),
            ),
          ),
        ),
        const SizedBox(height: ManoSpacing.md),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final ratio = isCard ? _cardRatio : _faceRatio;
              // As wide as allowed, but never taller than the room left.
              final width = (box.maxWidth * (isCard ? 1 : 0.72)).clamp(
                0.0,
                box.maxHeight * ratio,
              );
              return Center(
                child: SizedBox(
                  key: const ValueKey('mano-capture-guide'),
                  width: width,
                  height: width / ratio,
                  child: AnimatedSwitcher(
                    duration: ManoMotion.normal,
                    child: DecoratedBox(
                      key: ValueKey(preview != null),
                      position: DecorationPosition.foreground,
                      decoration: ShapeDecoration(
                        shape: outline.copyWith(
                          side: const BorderSide(
                            color: ManoColors.sand,
                            width: 3,
                          ),
                        ),
                      ),
                      child: ClipPath(
                        clipper: ShapeBorderClipper(shape: outline),
                        child: SizedBox.expand(child: preview),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (helpLabel != null && onHelp != null) ...[
          const SizedBox(height: ManoSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: ManoColors.sand,
              shape: const StadiumBorder(),
              child: InkWell(
                onTap: onHelp,
                customBorder: const StadiumBorder(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ManoSpacing.md,
                    ManoSpacing.sm,
                    ManoSpacing.sm,
                    ManoSpacing.sm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        helpLabel!,
                        style: text.labelLarge?.copyWith(color: ManoColors.ink),
                      ),
                      const SizedBox(width: ManoSpacing.sm),
                      const Icon(
                        Icons.help_rounded,
                        size: 22,
                        color: ManoColors.ink,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
