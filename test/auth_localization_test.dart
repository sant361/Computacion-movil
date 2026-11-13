import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_app/l10n/app_text.dart';
import 'package:streaming_app/screens/auth/login_screen.dart';
import 'package:streaming_app/screens/auth/register_screen.dart';
import 'package:streaming_app/screens/menu_screen.dart';
import 'package:streaming_app/state/app_state.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Widget app(Widget screen) => ListenableBuilder(listenable: appState,
    builder: (_, __) => MaterialApp(
      locale: Locale(appState.languageCode),
      supportedLocales: const [Locale('es'), Locale('en'), Locale('fr')],
      localizationsDelegates: const [AppStrings.delegate, ...GlobalMaterialLocalizations.delegates],
      home: screen,
    ));

  testWidgets('el selector del acceso cambia el idioma y los errores', (tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await appState.setLanguage('es');
    await tester.pumpWidget(app(const LoginScreen()));
    await tester.tap(find.byTooltip('Idioma'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Choose the application language'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('SIGN IN'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    await appState.setLanguage('fr');
    await tester.pumpAndSettle();
    expect(find.text('Mot de passe'), findsOneWidget);
  });

  testWidgets('registro y menú usan las traducciones sin traducir el catálogo', (tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await appState.setLanguage('en');
    await tester.pumpWidget(app(const RegisterScreen()));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Show password'), findsOneWidget);
    expect(find.text('Use at least 6 characters'), findsOneWidget);
    await tester.pumpWidget(app(const MenuScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    expect(const AppStrings(Locale('en')).text('Inception'), 'Inception');
  });
}
