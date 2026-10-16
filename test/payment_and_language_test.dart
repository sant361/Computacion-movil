import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_app/state/app_state.dart';
import 'package:streaming_app/l10n/app_text.dart';
import 'package:streaming_app/screens/payments/payment_methods_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('tarjetas persisten por cuenta sin almacenar número completo ni CVV', () async {
    final state = AppState();
    await state.load();
    await state.loadPaymentMethods('user-a');
    await state.addPaymentMethod(last4: '4242', brand: 'Visa', expiry: '12/35',
      holder: 'Usuario de prueba', isDefault: false);
    final prefs = await SharedPreferences.getInstance();
    final stored = jsonDecode(prefs.getString('paymentMethods:user-a')!) as List;
    expect((stored.first as Map).keys, isNot(contains('cvv')));
    expect((stored.first as Map).keys, isNot(contains('cardNumber')));
    expect((stored.first as Map)['last4'], '4242');

    final restored = AppState();
    await restored.load();
    await restored.loadPaymentMethods('user-a');
    expect(restored.paymentMethods.single['nombre'], 'Visa •••• 4242');
    expect(restored.paymentMethods.single['principal'], 'true');
    await restored.loadPaymentMethods('user-b');
    expect(restored.paymentMethods, isEmpty);
    await restored.loadPaymentMethods('user-a');
    expect(restored.paymentMethods, hasLength(1));
    await restored.logout();
    expect(restored.paymentMethods, isEmpty);
  });

  test('cambiar y eliminar la principal conserva una única principal', () async {
    final state = AppState();
    await state.load();
    await state.loadPaymentMethods('user-a');
    await state.addPaymentMethod(last4: '4242', brand: 'Visa', expiry: '12/35',
      holder: 'Prueba', isDefault: true);
    await state.addPaymentMethod(last4: '1881', brand: 'Mastercard', expiry: '11/35',
      holder: 'Prueba', isDefault: true);
    final secondId = state.paymentMethods.last['id']!;
    expect(state.paymentMethods.where((m) => m['principal'] == 'true'), hasLength(1));
    expect(state.paymentMethods.last['principal'], 'true');
    await state.setDefaultPaymentMethod(state.paymentMethods.first['id']!);
    expect(state.paymentMethods.first['principal'], 'true');
    await state.setDefaultPaymentMethod(secondId);
    await state.removePaymentMethod(secondId);
    expect(state.paymentMethods.single['principal'], 'true');
    final restored = AppState();
    await restored.loadPaymentMethods('user-a');
    expect(restored.paymentMethods.single['last4'], '4242');
  });

  test('idioma persiste y rechaza códigos desconocidos', () async {
    final state = AppState();
    await state.load();
    await state.setLanguage('fr');
    final restored = AppState();
    await restored.load();
    expect(restored.languageCode, 'fr');
    await restored.setLanguage('xx');
    expect(restored.languageCode, 'fr');
    expect(const AppStrings(Locale('en')).text('Cerrar sesión'), 'Sign out');
    expect(const AppStrings(Locale('fr')).text('Métodos de pago'), 'Moyens de paiement');
  });

  testWidgets('guardar tarjeta regresa y muestra la tarjeta nueva', (tester) async {
    await appState.load();
    await appState.loadPaymentMethods('widget-user');
    await tester.pumpWidget(const MaterialApp(home: PaymentMethodsScreen()));
    expect(find.text('No tienes métodos de pago guardados'), findsOneWidget);
    await tester.tap(find.text('+ Agregar método'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '4242424242424242');
    await tester.enterText(fields.at(1), '12/35');
    await tester.enterText(fields.at(2), '123');
    await tester.enterText(fields.at(3), 'Prueba');
    await tester.ensureVisible(find.text('GUARDAR MÉTODO'));
    await tester.tap(find.text('GUARDAR MÉTODO'));
    await tester.pumpAndSettle();
    expect(find.text('Visa •••• 4242'), findsOneWidget);
    expect(find.text('Principal'), findsOneWidget);
    expect(find.text('No tienes métodos de pago guardados'), findsNothing);
  });
}
