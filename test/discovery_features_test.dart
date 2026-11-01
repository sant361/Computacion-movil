import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_app/screens/search_screen.dart';
import 'package:streaming_app/screens/catalog/my_list_screen.dart';
import 'package:streaming_app/screens/catalog/viewing_history_screen.dart';
import 'package:streaming_app/state/app_state.dart';
import 'package:streaming_app/widgets/catalog_artwork.dart';

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

  testWidgets('el historial solo se borra tras confirmar', (tester) async {
    await appState.loadProfiles('historial-ui');
    await appState.saveWatchProgress('Risas en el aire',
        const Duration(seconds: 20), const Duration(seconds: 100),
        scope: appState.playbackScope);
    await tester.pumpWidget(const MaterialApp(home: ViewingHistoryScreen()));
    expect(find.text('Risas en el aire'), findsOneWidget);
    await tester.tap(find.byTooltip('Borrar historial'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Risas en el aire'), findsOneWidget);
    await tester.tap(find.byTooltip('Borrar historial'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar historial').last);
    await tester.pumpAndSettle();
    expect(
        find.text('Aún no hay reproducciones en este perfil.'), findsOneWidget);
  });

  testWidgets('una portada vacía o inválida conserva una imagen de respaldo',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: SizedBox(
            width: 100,
            height: 100,
            child: CatalogArtwork(url: 'archivo-no-valido'))));
    expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
