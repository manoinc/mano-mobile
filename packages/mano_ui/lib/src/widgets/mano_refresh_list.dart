import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A pull-to-refresh list of rows split by hairlines, with an empty message.
class ManoRefreshList extends StatelessWidget {
  const ManoRefreshList({
    required this.children,
    required this.emptyMessage,
    required this.onRefresh,
    super.key,
  });

  final List<Widget> children;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  // Always scrollable, so even an empty or short list can be pulled.
  static const _physics = AlwaysScrollableScrollPhysics();

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: children.isEmpty
        ? ListView(
            physics: _physics,
            padding: const EdgeInsets.all(ManoSpacing.lg),
            children: [
              const SizedBox(height: ManoSpacing.xl * 3),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: context.palette.muted),
              ),
            ],
          )
        : ListView.separated(
            physics: _physics,
            itemCount: children.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            itemBuilder: (context, index) => children[index],
          ),
  );
}
