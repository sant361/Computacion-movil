import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streaming_app/screens/auth/register_screen.dart';

void main() {
  testWidgets('las contraseñas se revelan independientemente y validan coincidencia', (tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(2), 'abcdef');
    await tester.enterText(fields.at(3), 'abcdeg');
    await tester.pump();
    expect(find.text('Longitud mínima cumplida'), findsOneWidget);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    final inputs = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(inputs[2].obscureText, isFalse);
    expect(inputs[3].obscureText, isTrue);
    await tester.tap(find.text('REGISTRARME'));
    await tester.pump();
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
  });
}
