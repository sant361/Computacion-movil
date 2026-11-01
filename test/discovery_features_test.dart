import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_app/screens/search_screen.dart';
import 'package:streaming_app/screens/catalog/my_list_screen.dart';
import 'package:streaming_app/state/app_state.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('la búsqueda combina nombre sin acentos y los cuatro filtros',
      (tester) async {
    await appState.loadProfiles('busqueda');
    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));
    await tester.enterText(find.byType(TextField), 'ultima broma');
    await tester.pump();
    expect(find.text('1 título'), findsOneWidget);
    expect(find.text('La última broma'), findsOneWidget);
    await tester.tap(find.text('Filtros'));
    await tester.pump();
    for (final label in ['Comedia', '2022', 'Inglés', '60 a 100 min']) {
      final chip = find.widgetWithText(FilterChip, label);
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pump();
    }
    await tester.scrollUntilVisible(find.text('Filtros (4)'), -200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Filtros (4)'), findsOneWidget);
    expect(find.text('1 título'), findsOneWidget);
    final wrongYear = find.widgetWithText(FilterChip, '2026');
    await tester.ensureVisible(wrongYear);
    await tester.tap(wrongYear);
    await tester.pump();
    final originalYear = find.widgetWithText(FilterChip, '2022');
    await tester.tap(originalYear);
    await tester.pump();
    await tester.scrollUntilVisible(find.text('0 títulos'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('0 títulos'), findsOneWidget);
    expect(find.text('No encontramos títulos'), findsOneWidget);
  });

  testWidgets('Mi lista cambia con el perfil y permite quitar favoritos',
      (tester) async {
    await appState.loadProfiles('favoritos-ui');
    appState.toggleMyList('Risas en el aire');
    await tester.pumpWidget(const MaterialApp(home: MyListScreen()));
    expect(find.text('Risas en el aire'), findsOneWidget);
    await appState.setActiveProfile('Luis');
    await tester.pump();
    expect(find.text('Risas en el aire'), findsNothing);
    await appState.setActiveProfile('Ana');
    await tester.pump();
    await tester.tap(find.byTooltip('Quitar Risas en el aire de Mi lista'));
    await tester.pump();
    expect(find.text('Risas en el aire'), findsNothing);
    expect(find.text('Guarda títulos desde su ficha para encontrarlos aquí.'),
        findsOneWidget);
  });
}
