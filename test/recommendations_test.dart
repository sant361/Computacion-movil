import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_app/state/app_state.dart';
import 'package:streaming_app/screens/home_screen.dart';
import 'package:streaming_app/screens/content_detail_screen.dart';

Future<void> watch(AppState state, String title, {int seconds = 10}) =>
    state.saveWatchProgress(
        title, Duration(seconds: seconds), const Duration(seconds: 100),
        scope: state.playbackScope);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sin historial ofrece ocho títulos únicos ordenados por año', () async {
    final state = AppState();
    await state.loadProfiles('cuenta');
    expect(state.hasViewingHistory, isFalse);
    final recommendations = state.recommendations;
    expect(recommendations, hasLength(8));
    expect(recommendations.map((item) => item.title).toSet(), hasLength(8));
    for (var i = 1; i < recommendations.length; i++) {
      expect(recommendations[i - 1].year,
          greaterThanOrEqualTo(recommendations[i].year));
    }
    expect(state.recommendations.map((item) => item.title),
        recommendations.map((item) => item.title));
  });

  test(
      'prioriza géneros por títulos distintos, sin inflar votos con cada guardado',
      () async {
    final state = AppState();
    await state.loadProfiles('cuenta');
    await watch(state, 'Risas en el aire');
    await watch(state, 'La última broma');
    for (var second = 1; second < 6; second++) {
      await watch(state, 'Furia desatada', seconds: second);
    }
    final items = state.recommendations;
    expect(state.hasViewingHistory, isTrue);
    expect(items.take(5).every((item) => item.genre == 'Comedia'), isTrue);
    expect(items.skip(5).every((item) => item.genre == 'Acción'), isTrue);
    expect(
        items.any((item) => [
              'Risas en el aire',
              'La última broma',
              'Furia desatada'
            ].contains(item.title)),
        isFalse);
  });

  test('conserva gustos al terminar, reiniciar y volver a abrir la aplicación',
      () async {
    final state = AppState();
    await state.loadProfiles('cuenta');
    await watch(state, 'Furia desatada');
    await watch(state, 'Furia desatada', seconds: 100);
    await watch(state, 'Furia desatada', seconds: 0);
    final restored = AppState();
    await restored.loadProfiles('cuenta');
    expect(restored.watchProgress('Furia desatada'), isNull);
    expect(restored.hasViewingHistory, isTrue);
    expect(restored.recommendations.first.genre, 'Acción');
    expect(
        restored.recommendations.any((item) => item.title == 'Furia desatada'),
        isFalse);
  });

  test('cada perfil y cuenta conserva sus preferencias', () async {
    final state = AppState();
    await state.loadProfiles('cuenta');
    await watch(state, 'Cartas al atardecer');
    await state.setActiveProfile('Luis');
    expect(state.hasViewingHistory, isFalse);
    await watch(state, 'Aventuras de Pipo');
    expect(state.recommendations.first.genre, 'Infantil');
    await state.setActiveProfile('Ana');
    expect(state.recommendations.first.genre, 'Romance');
    await state.logout();
    expect(state.hasViewingHistory, isFalse);
    await state.loadProfiles('otra-cuenta');
    expect(state.hasViewingHistory, isFalse);
    await state.loadProfiles('cuenta');
    expect(state.recommendations.first.genre, 'Romance');
    await state.removeProfile('Ana');
    await state.addProfile('Ana');
    await state.setActiveProfile('Ana');
    expect(state.hasViewingHistory, isFalse);
  });

  test('respeta el control parental aunque el historial prefiera otro género',
      () async {
    final state = AppState();
    await state.loadProfiles('cuenta');
    await watch(state, 'El silencio del lago');
    await state.saveParentalSettings(
        maxRating: 'TP',
        restrictByProfile: true,
        blockPurchases: false,
        pin: '');
    expect(state.recommendations, isNotEmpty);
    expect(state.recommendations.every((item) => item.rating == 'TP'), isTrue);
  });

  test('si ya se vio todo no recomienda los mismos títulos', () async {
    final state = AppState();
    await state.loadProfiles('cuenta');
    for (final item in state.catalog) {
      await watch(state, item.title);
    }
    expect(state.recommendations, isEmpty);
  });

  test('aprovecha historiales anteriores y tolera preferencias dañadas',
      () async {
    SharedPreferences.setMockInitialValues({
      'viewedTitles': 'dato inválido',
      'watchHistory':
          '{"[\\"cuenta\\",\\"Ana\\"]":{"El silencio del lago":[20000,100000]}}',
    });
    final state = AppState();
    await state.loadProfiles('cuenta');
    expect(state.hasViewingHistory, isTrue);
    expect(state.recommendations.first.genre, 'Suspenso');
    expect(state.watchProgress('El silencio del lago')!.positionMs, 20000);
  });

  testWidgets(
      'inicio actualiza las recomendaciones del perfil y abre el título elegido',
      (tester) async {
    await appState.loadProfiles('cuenta');
    await watch(appState, 'Risas en el aire');
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    final section = find.byKey(const ValueKey('recommendations'));
    await tester.scrollUntilVisible(section, 300,
        scrollable: find.byType(Scrollable).first);
    expect(
        find.descendant(of: section, matching: find.text('Elegidas para ti')),
        findsOneWidget);
    expect(
        find.descendant(
            of: section, matching: find.text('Según los géneros que ves')),
        findsOneWidget);
    await appState.setActiveProfile('Luis');
    await tester.pump();
    expect(find.descendant(of: section, matching: find.text('Para descubrir')),
        findsOneWidget);
    await appState.setActiveProfile('Ana');
    await tester.pump();
    final title = appState.recommendations.first.title;
    final card = find.descendant(of: section, matching: find.text(title));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<ContentDetailScreen>(find.byType(ContentDetailScreen))
            .title,
        title);
  });
}
