import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/profile/skills_row.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

ServiceOffer _offer(String id, String service) => ServiceOffer(
  id: id,
  jobServiceId: service,
  offerantId: 'w1',
  rateType: RateType.fixed,
  amountCop: 85000,
  zone: 'Chapinero',
  status: OfferStatus.active,
);

void main() {
  testWidgets('two offers of one service show one chip', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myOffersProvider.overrideWith(
            (ref) async => [_offer('o1', 's1'), _offer('o2', 's1')],
          ),
          jobServiceProvider.overrideWith(
            (ref, id) async => const JobService(
              id: 's1',
              title: 'Reparación de fugas',
              description: '',
              category: 'plumbing',
            ),
          ),
        ],
        child: MaterialApp(
          theme: ManoTheme.light(),
          home: const Scaffold(body: SkillsRow()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reparación de fugas'), findsOneWidget);
  });
}
