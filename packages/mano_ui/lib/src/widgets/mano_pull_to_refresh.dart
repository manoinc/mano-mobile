import 'package:flutter/material.dart';

/// Pull down anywhere on [child] to call [onRefresh], whether it's a list or an empty state.
class ManoPullToRefresh extends StatelessWidget {
  const ManoPullToRefresh({
    required this.onRefresh,
    required this.child,
    super.key,
  });

  final Future<void> Function() onRefresh;

  /// Fills the space it's given; a list inside scrolls on its own.
  final Widget child;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    // The wrapper is depth 0; a list inside it is depth 1.
    notificationPredicate: (notification) => notification.depth <= 1,
    child: LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(height: box.maxHeight, child: child),
      ),
    ),
  );
}
