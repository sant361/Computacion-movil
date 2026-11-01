import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_app/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streaming_app/data/catalog_item.dart';
import 'package:streaming_app/services/catalog_store.dart';
import 'package:streaming_app/screens/admin/catalog_editor_screen.dart';
import 'package:streaming_app/screens/admin/content_panel_screen.dart';
import 'package:streaming_app/screens/admin/analytics_panel_screen.dart';

const movie = CatalogItem(
    id: 'movie-1',
    title: 'Una película',
    genre: 'Comedia',
    year: 2024,
    description: 'Una sinopsis',
    language: 'Español',
    durationMinutes: 92,
    videoUrl: 'https://example.com/movie.mp4',
    trailerUrl: 'https://example.com/trailer.mp4',
    posterUrl: 'https://example.com/poster.jpg',
    subtitleUrl: 'https://example.com/subtitles.srt',
    ageRating: '+14');

class MemoryCatalogStore implements CatalogStore {
  final List<CatalogItem> items = [];
  bool failWrites = false;
  int writes = 0;
  @override
  Future<List<CatalogItem>> load() async => List.of(items);
  @override
  Future<CatalogItem> add(CatalogItem item) async {
    if (failWrites) throw StateError('sin conexión');
    writes++;
    final saved = item.copyWith(id: 'id-${items.length + 1}');
    items.add(saved);
    return saved;
  }

  @override
  Future<void> update(CatalogItem item) async {
    if (failWrites) throw StateError('sin conexión');
    writes++;
    items[items.indexWhere((old) => old.id == item.id)] = item;
  }

  @override
  Future<void> delete(CatalogItem item) async {
    if (failWrites) throw StateError('sin conexión');
    writes++;
    items.removeWhere((old) => old.id == item.id);
  }

  @override
  Future<List<Map<String, dynamic>>> statistics() async => [
        {'title': movie.title, 'genre': movie.genre, 'plays': 4},
      ];
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'administrador agrega, edita y elimina el catálogo real sin sembrar ejemplos',
      () async {
    final store = MemoryCatalogStore();
    final state = AppState(catalogStore: store, adminStatus: (_) async => true);
    addTearDown(state.dispose);
    await state.loadAdminStatus('admin');
    await state.refreshCatalog();
    expect(state.adminCatalog, isEmpty);
    await state.addCatalogItem(movie.copyWith(id: ''));
    final saved = state.adminCatalog.single;
    expect(saved.id, 'id-1');
    expect(state.catalog.single.title, movie.title);
    await state.updateCatalogItem(saved.copyWith(title: 'Título editado'));
    expect(state.catalog.single.title, 'Título editado');
    expect(state.catalog.single.videoUrl, movie.videoUrl);
    expect((await state.catalogStatistics()).single['plays'], 4);
    store.failWrites = true;
    await expectLater(
        state.deleteCatalogItem(state.adminCatalog.single), throwsStateError);
    expect(state.adminCatalog, hasLength(1));
    store.failWrites = false;
    await state.deleteCatalogItem(state.adminCatalog.single);
    expect(state.catalog, isEmpty);
    expect(store.writes, 3);
  });

  test(
      'una cuenta sin rol no puede mutar el catálogo aunque conozca sus métodos',
      () async {
    final store = MemoryCatalogStore();
    final state =
        AppState(catalogStore: store, adminStatus: (_) async => false);
    addTearDown(state.dispose);
    await state.loadAdminStatus('usuario');
    await expectLater(state.addCatalogItem(movie), throwsStateError);
    await expectLater(state.updateCatalogItem(movie), throwsStateError);
    await expectLater(state.deleteCatalogItem(movie), throwsStateError);
    await expectLater(state.catalogStatistics(), throwsStateError);
    expect(state.adminCatalog, isEmpty);
    expect(store.writes, 0);
  });
  test('serializa videos, portada, clasificación y temporadas sin perder datos',
      () {
    final series = movie.copyWith(episodes: const [
      CatalogEpisode(
          id: 'second',
          title: 'Segundo',
          videoUrl: 'https://example.com/2.mp4',
          subtitleUrl: 'https://example.com/2.srt',
          season: 2,
          number: 1),
      CatalogEpisode(
          id: 'first',
          title: 'Primero',
          videoUrl: 'https://example.com/1.mp4',
          season: 1,
          number: 1),
    ]);
    final restored = CatalogItem.fromJson(series.toJson(), id: series.id);
    expect(restored.id, 'movie-1');
    expect(restored.toJson(), series.toJson());
    expect(restored.rating, '+14');
    expect(
        restored.orderedEpisodes.map((e) => e.title), ['Primero', 'Segundo']);
    expect(restored.orderedEpisodes.first.progressKey(restored.title),
        'Una película · T1 E1 · Primero');
  });

  test('los documentos antiguos conservan clasificación y valores por defecto',
      () {
    final old = CatalogItem.fromJson(
        {'title': 'Anterior', 'genre': 'Infantil', 'year': 2020});
    expect(old.rating, 'TP');
    expect(old.language, 'Español');
    expect(old.episodes, isEmpty);
    expect(old.videoUrl, isEmpty);
    expect(old.copyWith(ageRating: 'desconocida').rating, '+18');
    expect(old.copyWith(genre: 'Suspenso').rating, '+18');
  });

  test('valida enlaces y episodios completos antes de publicar', () {
    expect(movie.validationError, isNull);
    expect(movie.copyWith(videoUrl: 'javascript:alert(1)').validationError,
        isNotNull);
    expect(movie.copyWith(videoUrl: '').validationError, isNotNull);
    expect(movie.copyWith(year: 1800).validationError, isNotNull);
    expect(movie.copyWith(durationMinutes: 0).validationError, isNotNull);
    expect(movie.copyWith(title: '   ').validationError, isNotNull);
    expect(
        movie.copyWith(videoUrl: '', episodes: const [
          CatalogEpisode(title: 'Inicio', videoUrl: 'https://example.com/e.mp4')
        ]).validationError,
        isNull);
    expect(
        movie.copyWith(episodes: const [
          CatalogEpisode(
              id: 'a', title: 'Inicio', videoUrl: 'https://example.com/a.mp4'),
          CatalogEpisode(
              id: 'b',
              title: 'Repetido',
              videoUrl: 'https://example.com/b.mp4'),
        ]).validationError,
        isNotNull);
  });

  test('el repositorio no permite escribir ni leer estadísticas sin sesión',
      () async {
    final store = FirestoreCatalogStore(authenticatedUserId: () => null);
    await expectLater(store.add(movie), throwsStateError);
    await expectLater(store.update(movie), throwsStateError);
    await expectLater(store.delete(movie), throwsStateError);
    await expectLater(store.statistics(), throwsStateError);
  });

  testWidgets('editar un título conserva sus archivos y episodios',
      (tester) async {
    final initial = movie.copyWith(episodes: const [
      CatalogEpisode(
          id: 'e1', title: 'Inicio', videoUrl: 'https://example.com/e1.mp4'),
    ]);
    CatalogItem? result;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      result = await Navigator.push<CatalogItem>(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  CatalogEditorScreen(initial: initial)));
                    },
                    child: const Text('Abrir editor'))))));
    await tester.tap(find.text('Abrir editor'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('catalog-Título')), 'Título corregido');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(result?.title, 'Título corregido');
    expect(result?.id, initial.id);
    expect(result?.videoUrl, initial.videoUrl);
    expect(result?.posterUrl, initial.posterUrl);
    expect(result?.episodes.first.id, 'e1');
    expect(result?.description, initial.description);
  });

  testWidgets('los paneles administrativos bloquean a una cuenta sin permisos',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ContentPanelScreen()));
    expect(find.text('Esta sección está disponible para administradores.'),
        findsOneWidget);
    expect(find.text('Nuevo'), findsNothing);
    await tester.pumpWidget(const MaterialApp(home: AnalyticsPanelScreen()));
    expect(find.text('Esta sección está disponible para administradores.'),
        findsOneWidget);
  });
}
