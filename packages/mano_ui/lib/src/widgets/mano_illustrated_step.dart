import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_emphasis_text.dart';
import 'mano_primary_button.dart';
import 'mano_quiet_button.dart';

/// A step led by a full-bleed picture: the picture, one line, one action.
class ManoIllustratedStep extends StatelessWidget {
  const ManoIllustratedStep({
    required this.illustration,
    required this.headline,
    required this.primaryLabel,
    required this.onPrimary,
    this.headlineEmphasis,
    this.onBack,
    this.secondaryLabel,
    this.onSecondary,
    this.notice,
    this.busy = false,
    super.key,
  });

  /// Fills the top of the screen; the app supplies it, cropped to cover.
  final Widget illustration;

  final String headline;

  /// A fragment of [headline] painted in the accent.
  final String? headlineEmphasis;

  final String primaryLabel;
  final VoidCallback? onPrimary;

  /// A round back button over the picture; none when null.
  final VoidCallback? onBack;

  /// A quiet second action under the primary; both halves or neither.
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Built by the screen, above the action.
  final Widget? notice;

  /// Spins the primary and holds the rest.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSecondary = secondaryLabel != null && onSecondary != null;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: ManoColors.sand,
                  child: ClipRect(child: illustration),
                ),
                if (onBack != null)
                  SafeArea(
                    bottom: false,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(ManoSpacing.md),
                        child: IconButton.filled(
                          onPressed: busy ? null : onBack,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          iconSize: 20,
                          tooltip: 'Atrás',
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.surface,
                            foregroundColor: ManoColors.ink,
                            disabledBackgroundColor: theme.colorScheme.surface,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  ManoSpacing.lg,
                  ManoSpacing.lg,
                  ManoSpacing.lg,
                  ManoSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: ManoEmphasisText(
                          headline,
                          emphasis: headlineEmphasis,
                          style: theme.textTheme.headlineLarge,
                        ),
                      ),
                    ),
                    if (notice != null) ...[
                      notice!,
                      const SizedBox(height: ManoSpacing.md),
                    ],
                    ManoPrimaryButton(
                      label: primaryLabel,
                      busy: busy,
                      onPressed: onPrimary,
                    ),
                    if (hasSecondary) ...[
                      const SizedBox(height: ManoSpacing.xs),
                      ManoQuietButton(
                        label: secondaryLabel!,
                        busy: busy,
                        onPressed: onSecondary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
