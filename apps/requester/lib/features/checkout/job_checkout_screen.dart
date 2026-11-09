import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../activity/load_error.dart';
import 'checkout_form.dart';
import 'checkout_labels.dart';
import 'checkout_status_view.dart';

/// Pays a finished job: the form, then the status of the payment.
class JobCheckoutScreen extends ConsumerStatefulWidget {
  const JobCheckoutScreen({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<JobCheckoutScreen> createState() => _JobCheckoutScreenState();
}

class _JobCheckoutScreenState extends ConsumerState<JobCheckoutScreen> {
  final _phone = TextEditingController();
  final _legalId = TextEditingController();
  late final TextEditingController _email;
  late final AppLifecycleListener _lifecycle;
  late JobPaymentDraft _draft;

  JobCheckoutController get _controller =>
      ref.read(jobCheckoutProvider.notifier);

  @override
  void initState() {
    super.initState();
    final email = ref.read(accountEmailProvider);
    _email = TextEditingController(text: email);
    _draft = JobPaymentDraft(jobId: widget.jobId, payerEmail: email);
    // Back from Nequi or the bank: look at once instead of waiting for the next poll.
    _lifecycle = AppLifecycleListener(onResume: () => _controller.checkNow());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _phone.dispose();
    _legalId.dispose();
    _email.dispose();
    super.dispose();
  }

  void _update(JobPaymentDraft Function(JobPaymentDraft) change) =>
      setState(() => _draft = change(_draft));

  Future<void> _openBank(String url) async {
    final opened = await ref.read(externalLinkOpenerProvider)(Uri.parse(url));
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos abrir la página del banco.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(jobCheckoutProvider);
    final job = ref.watch(jobProvider(widget.jobId));
    final form = flow is CheckoutIdle || flow is CheckoutSubmitting;
    void close() => Navigator.of(context).pop();

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar y pagar')),
      body: switch (job) {
        AsyncData(value: final job?) => AnimatedSwitcher(
          duration: ManoMotion.normal,
          child: form
              ? CheckoutForm(
                  key: const ValueKey('form'),
                  job: job,
                  draft: _draft,
                  phone: _phone,
                  legalId: _legalId,
                  email: _email,
                  onChanged: _update,
                )
              : CheckoutStatusView(
                  key: const ValueKey('status'),
                  flow: flow,
                  providerName: job.provider.displayName.isEmpty
                      ? 'tu profesional'
                      : job.provider.displayName,
                  onOpenBank: _openBank,
                  onCheckAgain: _controller.checkNow,
                  onRetry: _controller.reset,
                  onDone: close,
                  onClose: close,
                ),
        ),
        AsyncData() || AsyncError() => ActivityLoadError(
          message: 'No pudimos cargar este trabajo.',
          onRetry: () => ref.invalidate(jobProvider(widget.jobId)),
        ),
        _ => const Center(child: ManoLoader()),
      },
      bottomNavigationBar: switch (job.value) {
        final job? when form => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(ManoSpacing.md),
            child: ManoPrimaryButton(
              label: payLabel(job.payableCop),
              busy: flow is CheckoutSubmitting,
              onPressed: _draft.isValid ? () => _controller.pay(_draft) : null,
            ),
          ),
        ),
        _ => null,
      },
    );
  }
}
