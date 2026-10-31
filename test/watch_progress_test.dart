import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_app/state/app_state.dart';
import 'package:streaming_app/screens/home_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('el progreso persiste y queda separado por perfil y cuenta', () async {
    final state = AppState();
    await state.loadProfiles('cuenta-a');
    await state.saveWatchProgress(
        'Serie', const Duration(seconds: 30), const Duration(seconds: 100),
        scope: state.playbackScope);
    await state.setActiveProfile('Luis');
    expect(state.watchProgress('Serie'), isNull);
    await state.setActiveProfile('Ana');
    expect(state.watchProgress('Serie')!.positionMs, 30000);
    final restored = AppState();
    await restored.loadProfiles('cuenta-a');
    expect(restored.watchProgress('Serie')!.fraction, 0.3);
    await restored.loadProfiles('cuenta-b');
    expect(restored.watchProgress('Serie'), isNull);
  });

  test('terminar o volver al inicio elimina el pendiente', () async {
    final state = AppState();
    await state.loadProfiles('cuenta');
    for (final end in [Duration.zero, const Duration(seconds: 100)]) {
      await state.saveWatchProgress(
          'Serie', const Duration(seconds: 30), const Duration(seconds: 100),
          scope: state.playbackScope);
      await state.saveWatchProgress('Serie', end, const Duration(seconds: 100),
          scope: state.playbackScope);
      expect(state.watchProgress('Serie'), isNull);
    }
  });

  test('una sesión conserva su perfil aunque cambie el perfil activo',
      () async {
    final state = AppState();
    await state.loadProfiles('cuenta');
    final scope = state.playbackScope;
    await state.setActiveProfile('Luis');
    await state.saveWatchProgress(
        'Serie', const Duration(seconds: 20), const Duration(seconds: 100),
        scope: scope);
    expect(state.watchProgress('Serie'), isNull);
    await state.setActiveProfile('Ana');
    expect(state.watchProgress('Serie')!.positionMs, 20000);
    await state.removeProfile('Ana');
    await state.addProfile('Ana');
    await state.setActiveProfile('Ana');
    expect(state.watchProgress('Serie'), isNull);
  });

  testWidgets('inicio muestra progreso real y oculta pendientes de otro perfil',
      (tester) async {
    await appState.loadProfiles('cuenta');
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    expect(find.text('Seguir viendo'), findsNothing);
    await appState.saveWatchProgress(appState.catalog.first.title,
        const Duration(seconds: 25), const Duration(seconds: 100),
        scope: appState.playbackScope);
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Seguir viendo'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Seguir viendo'), findsOneWidget);
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        0.25);
    await appState.setActiveProfile('Luis');
    await tester.pump();
    expect(find.text('Seguir viendo'), findsNothing);
  });
}
