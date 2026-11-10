import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child, {TargetPlatform? platform}) => MaterialApp(
  theme: ManoTheme.light().copyWith(platform: platform),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

const _countries = [
  ManoCountryOption(
    code: 'CO',
    flag: '🇨🇴',
    name: 'Colombia',
    dialCode: '+57',
  ),
  ManoCountryOption(code: 'MX', flag: '🇲🇽', name: 'México', dialCode: '+52'),
  ManoCountryOption(
    code: 'EC',
    flag: '🇪🇨',
    name: 'Ecuador',
    dialCode: '+593',
  ),
];

void main() {
  group('ManoLabelledField', () {
    testWidgets('puts the label above an outlined rounded box', (tester) async {
      String? typed;
      await tester.pumpWidget(
        _host(
          ManoLabelledField(
            label: 'Número de celular',
            controller: TextEditingController(),
            onChanged: (value) => typed = value,
          ),
        ),
      );

      expect(find.text('Número de celular'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      final border = field.decoration!.enabledBorder! as OutlineInputBorder;
      expect(border.borderRadius, BorderRadius.circular(ManoRadius.card));
      await tester.enterText(find.byType(TextField), '300');
      expect(typed, '300');
    });

    testWidgets('an error replaces the helper', (tester) async {
      await tester.pumpWidget(
        _host(
          ManoLabelledField(
            label: 'Número',
            controller: TextEditingController(),
            helperText: 'Te enviaremos un código.',
            errorText: 'Revisa tu número.',
          ),
        ),
      );

      expect(find.text('Revisa tu número.'), findsOneWidget);
      expect(find.text('Te enviaremos un código.'), findsNothing);
    });

    testWidgets('as a select shows the value and reports taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          ManoLabelledField.select(
            label: 'País o región',
            value: 'Colombia (+57)',
            leading: const Text('🇨🇴'),
            onTap: () => taps++,
          ),
        ),
      );

      expect(find.text('País o región'), findsOneWidget);
      expect(find.text('🇨🇴'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.text('Colombia (+57)'));
      expect(taps, 1);
    });
  });

  group('ManoCountryPickerSheet', () {
    testWidgets('lists flag, name and dial code, and marks the chosen one', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ManoCountryPickerSheet(
            countries: _countries,
            selectedCode: 'CO',
            onSelected: (_) {},
          ),
        ),
      );

      expect(find.text('País o región'), findsOneWidget);
      expect(find.text('México'), findsOneWidget);
      expect(find.text('+52'), findsOneWidget);
      expect(find.text('🇲🇽'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('filters by name or dial code', (tester) async {
      await tester.pumpWidget(
        _host(
          ManoCountryPickerSheet(
            countries: _countries,
            selectedCode: 'CO',
            onSelected: (_) {},
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'méx');
      await tester.pump();
      expect(find.text('México'), findsOneWidget);
      expect(find.text('Colombia'), findsNothing);

      await tester.enterText(find.byType(TextField), '593');
      await tester.pump();
      expect(find.text('Ecuador'), findsOneWidget);
      expect(find.text('México'), findsNothing);
    });

    testWidgets('says so when nothing matches', (tester) async {
      await tester.pumpWidget(
        _host(
          ManoCountryPickerSheet(
            countries: _countries,
            selectedCode: 'CO',
            onSelected: (_) {},
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();

      expect(find.text('Sin resultados'), findsOneWidget);
    });

    testWidgets('reports the tapped country by code', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _host(
          ManoCountryPickerSheet(
            countries: _countries,
            selectedCode: 'CO',
            onSelected: (code) => picked = code,
          ),
        ),
      );

      await tester.tap(find.text('Ecuador'));
      expect(picked, 'EC');
    });
  });

  group('ManoBrandPillRow', () {
    testWidgets('draws equal icon-only pills that report taps', (tester) async {
      var google = 0;
      var email = 0;
      await tester.pumpWidget(
        _host(
          ManoBrandPillRow(
            pills: [
              ManoBrandPill(
                mark: const Icon(Icons.g_mobiledata),
                label: 'Continuar con Google',
                onPressed: () => google++,
              ),
              ManoBrandPill(
                mark: const Icon(Icons.mail_outline_rounded),
                label: 'Continuar con correo',
                onPressed: () => email++,
              ),
            ],
          ),
        ),
      );

      final widths = tester
          .widgetList<OutlinedButton>(find.byType(OutlinedButton))
          .map((b) => tester.getSize(find.byWidget(b)).width)
          .toSet();
      expect(widths, hasLength(1));
      expect(find.text('Continuar con Google'), findsNothing);

      await tester.tap(find.byTooltip('Continuar con Google'));
      await tester.tap(find.byTooltip('Continuar con correo'));
      expect(google, 1);
      expect(email, 1);
    });
  });

  group('ManoWelcomeActions', () {
    testWidgets('two equal flame pills side by side, then what goes below', (
      tester,
    ) async {
      var signIn = 0;
      var register = 0;
      await tester.pumpWidget(
        _host(
          ManoWelcomeActions(
            firstLabel: 'Iniciar sesión',
            onFirst: () => signIn++,
            secondLabel: 'Registrarse',
            onSecond: () => register++,
            below: const Text('plataforma'),
          ),
        ),
      );

      final buttons = find.byType(ManoPrimaryButton);
      expect(buttons, findsNWidgets(2));
      expect(
        tester.getSize(buttons.first).width,
        tester.getSize(buttons.last).width,
      );
      expect(
        tester.getTopLeft(buttons.first).dy,
        tester.getTopLeft(buttons.last).dy,
      );
      for (final b in tester.widgetList<ManoPrimaryButton>(buttons)) {
        expect(b.tone, ManoPrimaryTone.flame);
      }
      expect(find.text('plataforma'), findsOneWidget);

      await tester.tap(find.text('Iniciar sesión'));
      await tester.tap(find.text('Registrarse'));
      expect(signIn, 1);
      expect(register, 1);
    });
  });

  testWidgets('ManoHeroScaffold puts the actions under the headline', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ManoTheme.light(),
        home: ManoHeroScaffold(
          headline: 'Tu oficio, más cerca de tus clientes.',
          actions: ManoWelcomeActions(
            firstLabel: 'Iniciar sesión',
            onFirst: () {},
            secondLabel: 'Crear cuenta',
            onSecond: () {},
          ),
          footnote: 'Verificamos tu identidad.',
        ),
      ),
    );

    final headline = tester.getBottomLeft(
      find.text('Tu oficio, más cerca de tus clientes.'),
    );
    expect(
      tester.getTopLeft(find.text('Crear cuenta')).dy,
      greaterThan(headline.dy),
    );
    expect(find.byType(ManoPrimaryButton), findsNWidgets(2));
    expect(find.text('Verificamos tu identidad.'), findsOneWidget);
  });

  group('ManoSignInLayout', () {
    testWidgets('body, primary, a link, and the other ways at the bottom', (
      tester,
    ) async {
      var continued = 0;
      var closed = 0;
      var trouble = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ManoTheme.light(),
          home: ManoSignInLayout(
            title: 'Inicia sesión',
            body: const Text('campo'),
            primaryLabel: 'Continuar',
            onPrimary: () => continued++,
            onClose: () => closed++,
            linkLabel: '¿Problemas para entrar?',
            onLink: () => trouble++,
            footerLabel: 'O continúa con',
            footer: const Text('pills'),
          ),
        ),
      );

      expect(find.text('Inicia sesión'), findsOneWidget);
      expect(find.text('O continúa con'), findsOneWidget);
      final screen = tester.getSize(find.byType(Scaffold)).height;
      expect(
        tester.getBottomLeft(find.text('pills')).dy,
        greaterThan(screen * 0.8),
      );

      await tester.tap(find.text('Continuar'));
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.tap(find.text('¿Problemas para entrar?'));
      expect(continued, 1);
      expect(closed, 1);
      expect(trouble, 1);
    });

    testWidgets('a small phone at large text keeps the footer reachable', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ManoTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: ManoSignInLayout(
            title: 'Inicia sesión o regístrate',
            body: const SizedBox(height: 400, child: Text('campos')),
            primaryLabel: 'Continuar',
            onPrimary: () {},
            linkLabel: '¿Problemas para entrar?',
            onLink: () {},
            footerLabel: 'O continúa con',
            footer: TextButton(onPressed: () => taps++, child: const Text('x')),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      await tester.tap(find.text('x'));
      expect(taps, 1);
    });

    testWidgets('the keyboard hides the footer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ManoTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: 300)),
            child: ManoSignInLayout(
              title: 'Inicia sesión',
              body: SizedBox(),
              primaryLabel: 'Continuar',
              onPrimary: null,
              footerLabel: 'O continúa con',
              footer: Text('pills'),
            ),
          ),
        ),
      );

      expect(find.text('pills'), findsNothing);
    });

    testWidgets('without a footer there is no footer label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ManoTheme.light(),
          home: const ManoSignInLayout(
            title: 'Confirma tu número',
            message: 'Escribe el código que enviamos a +57 300 *** 4567.',
            body: SizedBox(),
            primaryLabel: 'Continuar',
            onPrimary: null,
            footerLabel: 'O continúa con',
          ),
        ),
      );

      expect(find.text('O continúa con'), findsNothing);
      expect(
        find.text('Escribe el código que enviamos a +57 300 *** 4567.'),
        findsOneWidget,
      );
    });

    testWidgets('busy shows the loader on the primary', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ManoTheme.light(),
          home: ManoSignInLayout(
            title: 'Inicia sesión',
            body: const SizedBox(),
            primaryLabel: 'Continuar',
            onPrimary: () {},
            busy: true,
          ),
        ),
      );

      expect(find.byType(ManoLoader), findsOneWidget);
    });
  });

  group('ManoPhoneField', () {
    testWidgets('a country select above a labelled phone box', (tester) async {
      var picks = 0;
      String? typed;
      final controller = TextEditingController();
      await tester.pumpWidget(
        _host(
          ManoPhoneField(
            controller: controller,
            countryFlag: '🇨🇴',
            country: 'Colombia (+57)',
            onCountryTap: () => picks++,
            onChanged: (value) => typed = value,
          ),
        ),
      );

      expect(find.text('País o región'), findsOneWidget);
      expect(find.text('Número de celular'), findsOneWidget);
      await tester.tap(find.text('Colombia (+57)'));
      expect(picks, 1);
      await tester.enterText(find.byType(TextField), '3001234567');
      expect(typed, '3001234567');
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.keyboardType, TextInputType.phone);
    });
  });

  group('ManoPhoneSignInScreen', () {
    Widget screen({
      TargetPlatform platform = TargetPlatform.android,
      String? codeSentTo,
      ValueChanged<String>? onCountrySelected,
      VoidCallback? onGoogle,
      VoidCallback? onApple,
      VoidCallback? onEmail,
      VoidCallback? onSendCode,
    }) => MaterialApp(
      theme: ManoTheme.light().copyWith(platform: platform),
      home: ManoPhoneSignInScreen(
        countries: _countries,
        countryCode: 'CO',
        onCountrySelected: onCountrySelected ?? (_) {},
        phone: '',
        onPhoneChanged: (_) {},
        onSendCode: onSendCode ?? () {},
        onTrouble: () {},
        googleMark: const SizedBox(key: Key('google')),
        appleMark: const SizedBox(key: Key('apple')),
        onGoogle: onGoogle,
        onApple: onApple,
        onEmail: onEmail,
        onClose: () {},
        codeSentTo: codeSentTo,
        code: '',
        onCodeChanged: (_) {},
        onVerify: () {},
        canVerify: false,
        onResend: () {},
        onChangeNumber: () {},
      ),
    );

    testWidgets('asks for the number with the country first', (tester) async {
      var sent = 0;
      await tester.pumpWidget(screen(onSendCode: () => sent++));

      expect(find.text('Inicia sesión o regístrate'), findsOneWidget);
      expect(find.text('Colombia (+57)'), findsOneWidget);
      expect(find.text('¿Problemas para entrar?'), findsOneWidget);
      expect(find.text('O continúa con'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      expect(sent, 1);
    });

    testWidgets('Android offers Google and email as icon pills', (
      tester,
    ) async {
      var google = 0;
      var email = 0;
      await tester.pumpWidget(
        screen(onGoogle: () => google++, onEmail: () => email++),
      );

      expect(find.byKey(const Key('apple')), findsNothing);
      await tester.tap(find.byTooltip('Continuar con Google'));
      await tester.tap(find.byTooltip('Continuar con correo'));
      expect(google, 1);
      expect(email, 1);
    });

    testWidgets('iOS offers Apple instead', (tester) async {
      var apple = 0;
      await tester.pumpWidget(
        screen(platform: TargetPlatform.iOS, onApple: () => apple++),
      );

      expect(find.byKey(const Key('google')), findsNothing);
      await tester.tap(find.byTooltip('Continuar con Apple'));
      expect(apple, 1);
    });

    testWidgets('the country opens the picker and reports the pick', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(screen(onCountrySelected: (c) => picked = c));

      await tester.tap(find.text('Colombia (+57)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('México'));
      await tester.pumpAndSettle();

      expect(picked, 'MX');
      expect(find.byType(ManoCountryPickerSheet), findsNothing);
    });

    testWidgets('once a code is sent it asks for the code', (tester) async {
      await tester.pumpWidget(screen(codeSentTo: '+57 300 *** 4567'));

      expect(find.text('Confirma tu número'), findsOneWidget);
      expect(
        find.text('Escribe el código que enviamos a +57 300 *** 4567.'),
        findsOneWidget,
      );
      expect(find.byType(ManoOtpField), findsOneWidget);
      expect(find.text('O continúa con'), findsNothing);
    });
  });
}
