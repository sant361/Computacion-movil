import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_app/screens/auth/login_screen.dart';

/// Prueba de interfaz (widget test): abre la pantalla de Login sin
/// necesitar un emulador ni un celular conectado.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
  }

  testWidgets('muestra los campos de usuario y contraseña, y el botón LOGIN', (tester) async {
    await pumpLogin(tester);

    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
  });

  testWidgets('muestra errores de validación si se intenta entrar con campos vacíos', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('LOGIN'));
    await tester.pump();

    expect(find.text('Ingresa tu usuario'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });

  testWidgets('el botón "Autocompletar datos" llena los campos', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Autocompletar datos'));
    await tester.pump();

    expect(find.text('usuario_demo'), findsOneWidget);
  });

  testWidgets('el ícono del ojo alterna si la contraseña se ve o no', (tester) async {
    await pumpLogin(tester);

    expect(find.byIcon(Icons.visibility_off), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });
}
