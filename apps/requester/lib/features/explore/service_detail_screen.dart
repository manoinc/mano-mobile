import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'category_icons.dart';

class ServiceDetailScreen extends ConsumerWidget {
  const ServiceDetailScreen({required this.serviceId, super.key});

  final String serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(jobServiceProvider(serviceId));
    final categories = ref.watch(serviceCategoriesProvider).value ?? const [];
    final found = service.value;

    return Scaffold(
      appBar: AppBar(),
      body: service.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ManoEmptyState(
          icon: Icons.wifi_off_outlined,
          message: 'No pudimos cargar este servicio.',
          ctaLabel: 'Reintentar',
          onCta: () => ref.invalidate(jobServiceProvider(serviceId)),
        ),
        data: (service) => service == null
            ? ManoEmptyState(
                icon: Icons.search_off,
                message: 'No encontramos este servicio. Puede que ya no esté disponible.',
                ctaLabel: 'Buscar otros servicios',
                onCta: () => context.canPop()
                    ? context.pop()
                    : context.go('/home/search'),
              )
            : _Details(
                category: categoryLabel(service.category, categories),
                title: service.title,
                description: service.description,
              ),
      ),
      bottomNavigationBar: found == null || service.hasError
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(ManoSpacing.md),
              child: ManoPrimaryButton(
                label: 'Ver ofertas',
                onPressed: () =>
                    context.push('/home/service/${found.id}/offers'),
              ),
            ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.category,
    required this.title,
    required this.description,
  });

  final String category;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(ManoSpacing.md),
      children: [
        Text(
          category,
          style: textTheme.labelMedium?.copyWith(color: ManoColors.clay),
        ),
        const SizedBox(height: ManoSpacing.sm),
        Text(title, style: textTheme.headlineSmall),
        const SizedBox(height: ManoSpacing.md),
        Text(
          description,
          style: textTheme.bodyLarge?.copyWith(color: ManoColors.muted),
        ),
      ],
    );
  }
}
