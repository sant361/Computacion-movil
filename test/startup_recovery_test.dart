import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streaming_app/main.dart';

void main() {
  testWidgets('un error de inicialización puede reintentarse sin reiniciar', (tester) async {
    var attempts = 0;
    Future<void> initialize() async {
      if (++attempts == 1) throw StateError('offline');
    }
    await tester.pumpWidget(MaterialApp(home: AppStartup(
      initialize: initialize,
      readyBuilder: (_) => const Text('Preparada'),
    )));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos iniciar la aplicación'), findsOneWidget);
    expect(find.text('Preparada'), findsNothing);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Preparada'), findsOneWidget);
  });

  testWidgets('reconstruir no repite la inicialización pendiente', (tester) async {
    var attempts = 0;
    final pending = Completer<void>();
    Future<void> initialize() { attempts++; return pending.future; }
    final key = GlobalKey();
    Widget app() => MaterialApp(home: AppStartup(key: key,
      initialize: initialize, readyBuilder: (_) => const Text('Preparada')));
    await tester.pumpWidget(app());
    await tester.pumpWidget(app());
    expect(attempts, 1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Preparada'), findsOneWidget);
  });
}
