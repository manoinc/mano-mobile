import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../features/registration/welcome_overlay.dart';
import 'app_router.dart';

/// The nav shell, embedded inside the app's outer widget tree rather than
/// owning it. [ManoRoot] has already decided this is where we are -- signed
/// in, or browsing as a guest -- so there is no auth gate left to apply here.
class RequesterShell extends ConsumerStatefulWidget {
  const RequesterShell({this.showWelcome = false, super.key});

  /// One-shot, raised right after a successful registration. The shell
  /// clears it through [OnboardingFlowNotifier.acknowledgeWelcome] once
  /// shown, the same contract [SessionNotifier.acknowledgeFailure] uses.
  final bool showWelcome;

  @override
  ConsumerState<RequesterShell> createState() => _RequesterShellState();
}

class _RequesterShellState extends ConsumerState<RequesterShell> {
  @override
  void initState() {
    super.initState();
    if (widget.showWelcome) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _welcome());
    }
  }

  Future<void> _welcome() async {
    if (!mounted) return;
    await showManoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          WelcomeOverlay(onStart: () => Navigator.of(context).pop()),
    );
    if (!mounted) return;
    ref.read(onboardingFlowProvider.notifier).acknowledgeWelcome();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(requesterRouterProvider);
    return Router<Object>.withConfig(config: router);
  }
}
