import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'provider_router.dart';

/// The nav shell, embedded inside the app's outer tree; the root has already decided we belong here.
class ProviderShell extends ConsumerWidget {
  const ProviderShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      Router<Object>.withConfig(config: ref.watch(providerRouterProvider));
}
