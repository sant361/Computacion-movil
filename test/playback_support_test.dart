import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_app/data/catalog_item.dart';
import 'package:streaming_app/playback/playback_support.dart';
import 'package:streaming_app/screens/content_detail_screen.dart';
import 'package:streaming_app/screens/player_screen.dart';
import 'package:streaming_app/screens/fullscreen_player_screen.dart';
import 'package:streaming_app/state/app_state.dart';

class FakeVideoPlatform extends VideoPlayerPlatform {
  final sources = <int, DataSource>{};
  final events = <int, StreamController<VideoEvent>>{};
  final positions = <int, Duration>{};
  final seeks = <Duration>[];
  @override
  Future<void> init() async {}
  @override
  Future<int?> create(DataSource dataSource) async {
    final id = sources.length + 1;
    sources[id] = dataSource;
    positions[id] = Duration.zero;
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    final controller = StreamController<VideoEvent>();
    events[playerId] = controller;
    controller.add(VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 20),
        size: const Size(640, 360)));
    return controller.stream;
  }

  @override
  Future<void> dispose(int playerId) async {
    events[playerId]?.close();
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> seekTo(int playerId, Duration position) async {
    positions[playerId] = position;
    seeks.add(position);
  }

  @override
  Future<Duration> getPosition(int playerId) async =>
      positions[playerId] ?? Duration.zero;
  @override
  Widget buildView(int playerId) => const SizedBox.expand();
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
  Future<void> setAllowBackgroundPlayback(bool allowBackgroundPlayback) async {}
}

Future<void> seedPlayback(CatalogItem item,
    {String? progressKey, int position = 0}) async {
  SharedPreferences.setMockInitialValues({
    'catalogCache': jsonEncode([
      {...item.toJson(), 'id': item.id}
    ]),
    if (progressKey != null)
      'watchHistory': jsonEncode({
        jsonEncode(['playback-user', 'Ana']): {
          progressKey: [position, 20000, 123]
        },
      }),
  });
  await appState.load();
  await appState.loadProfiles('playback-user');
}

Future<void> pumpPlayback(WidgetTester tester) async {
  for (var frame = 0; frame < 10; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  test('ordena episodios y encuentra el siguiente incluso al cambiar temporada',
      () {
    const first = CatalogEpisode(
        id: 'one',
        title: 'Inicio',
        videoUrl: 'https://media.example/one.mp4',
        season: 1,
        number: 1);
    const second = CatalogEpisode(
        id: 'two',
        title: 'Encuentro',
        videoUrl: 'https://media.example/two.mp4',
        season: 1,
        number: 2);
    const third = CatalogEpisode(
        id: 'three',
        title: 'Regreso',
        videoUrl: 'https://media.example/three.mp4',
        season: 2,
        number: 1);
    const item = CatalogItem(
        title: 'Serie',
        genre: 'Comedia',
        year: 2026,
        episodes: [third, first, second]);
    expect(orderedEpisodes(item), [first, second, third]);
    expect(nextEpisode(item, first), second);
    expect(nextEpisode(item, second), third);
    expect(nextEpisode(item, third), isNull);
    expect(nextEpisode(item, null), isNull);
    expect(
        first.progressKey(item.title), isNot(second.progressKey(item.title)));
  });

  test('lee subtítulos SRT y WebVTT con sus tiempos y texto', () {
    final srt = parseCaptionFile(
        '1\n00:00:01,000 --> 00:00:03,000\nHola\n\n2\n00:00:04,000 --> 00:00:05,000\nAdiós\n');
    expect(srt.captions, hasLength(2));
    expect(srt.captions.first.start, const Duration(seconds: 1));
    expect(srt.captions.last.text, 'Adiós');
    final vtt = parseCaptionFile(
        '\uFEFFWEBVTT\n\n00:00:01.000 --> 00:00:03.000\nBienvenido\n');
    expect(vtt.captions.single.text, 'Bienvenido');
    expect(vtt.captions.single.end, const Duration(seconds: 3));
    expect(() => parseCaptionFile('Esto no es un archivo de subtítulos'),
        throwsFormatException);
  });

  test('valida fuentes de video y conserva las horas al mostrar duración', () {
    expect(isPlayableUrl('https://media.example/movie.mp4'), isTrue);
    expect(isPlayableUrl(''), isFalse);
    expect(isPlayableUrl('javascript:alert(1)'), isFalse);
    expect(isPlayableUrl('file:///secret.mp4'), isFalse);
    expect(formatPlaybackTime(const Duration(hours: 2, minutes: 3, seconds: 4)),
        '2:03:04');
    expect(formatPlaybackTime(const Duration(seconds: 7)), '00:07');
  });

  testWidgets(
      'el temporizador pausa una sola vez y permite cancelar o reemplazar',
      (tester) async {
    var pauses = 0;
    final timer = PlaybackSleepTimer(() => pauses++);
    addTearDown(timer.dispose);
    timer.schedule(const Duration(minutes: 15));
    await tester.pump(const Duration(minutes: 14));
    expect(pauses, 0);
    timer.schedule(const Duration(minutes: 30));
    await tester.pump(const Duration(minutes: 29));
    expect(pauses, 0);
    await tester.pump(const Duration(minutes: 1));
    expect(pauses, 1);
    expect(timer.value, isNull);
    timer.schedule(const Duration(minutes: 15));
    timer.schedule(null);
    await tester.pump(const Duration(minutes: 16));
    expect(pauses, 1);
  });

  testWidgets(
      'sin video asignado informa la ausencia sin reproducir un video de muestra',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await appState.loadProfiles('prueba-player');
    await tester.pumpWidget(const MaterialApp(
        home: PlayerScreen(contentTitle: 'Risas en el aire')));
    await tester.pumpAndSettle();
    expect(find.text('Este título todavía no tiene un video disponible.'),
        findsOneWidget);
    expect(appState.watchProgress('Risas en el aire'), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('una ficha inexistente no expone controles de reproducción',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: ContentDetailScreen(title: 'No existe')));
    await tester.pumpAndSettle();
    expect(find.text('Este contenido no está disponible para este perfil.'),
        findsOneWidget);
    expect(find.text('REPRODUCIR'), findsNothing);
  });
  test('descarga subtítulos UTF-8 y rechaza respuestas de error', () async {
    final client = MockClient((request) async => http.Response.bytes(
        utf8.encode('1\n00:00:01,000 --> 00:00:02,000\nEspañol\n'), 200));
    final captions =
        await loadCaptionFile('https://media.example/sub.srt', client: client);
    expect(captions.captions.single.text, 'Español');
    final failed =
        MockClient((request) async => http.Response('No existe', 404));
    await expectLater(
        loadCaptionFile('https://media.example/missing.srt', client: failed),
        throwsStateError);
    client.close();
    failed.close();
  });

  testWidgets(
      'reproduce la URL del episodio y restaura su progreso independiente',
      (tester) async {
    const episode = CatalogEpisode(
        id: 'e2',
        title: 'Segundo',
        videoUrl: 'https://media.example/second.mp4',
        number: 2);
    const item = CatalogItem(
        id: 'series',
        title: 'Una serie',
        genre: 'Comedia',
        year: 2026,
        episodes: [episode]);
    await seedPlayback(item,
        progressKey: episode.progressKey(item.title), position: 5000);
    final platform = FakeVideoPlatform();
    VideoPlayerPlatform.instance = platform;
    await tester.pumpWidget(MaterialApp(
        home: PlayerScreen(contentTitle: item.title, episode: episode)));
    await pumpPlayback(tester);
    expect(platform.sources.values.single.uri, episode.videoUrl);
    expect(platform.seeks, contains(const Duration(seconds: 5)));
    expect(find.text('Segundo'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpPlayback(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('al terminar avanza una sola vez al siguiente episodio real',
      (tester) async {
    const first = CatalogEpisode(
        id: 'one',
        title: 'Primero',
        videoUrl: 'https://media.example/first.mp4');
    const second = CatalogEpisode(
        id: 'two',
        title: 'Segundo',
        videoUrl: 'https://media.example/second.mp4',
        number: 2);
    const item = CatalogItem(
        id: 'series',
        title: 'Una serie',
        genre: 'Comedia',
        year: 2026,
        episodes: [first, second]);
    await seedPlayback(item);
    final platform = FakeVideoPlatform();
    VideoPlayerPlatform.instance = platform;
    await tester
        .pumpWidget(MaterialApp(home: PlayerScreen(contentTitle: item.title)));
    await pumpPlayback(tester);
    expect(platform.sources, hasLength(1));
    platform.events[1]!.add(VideoEvent(eventType: VideoEventType.completed));
    await pumpPlayback(tester);
    expect(platform.sources, hasLength(2));
    expect(platform.sources[2]!.uri, second.videoUrl);
    expect(find.text('Segundo'), findsOneWidget);
    await pumpPlayback(tester);
    expect(platform.sources, hasLength(2));
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpPlayback(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el tráiler usa su URL sin modificar el progreso del título',
      (tester) async {
    const item = CatalogItem(
        id: 'movie',
        title: 'Una película',
        genre: 'Comedia',
        year: 2026,
        videoUrl: 'https://media.example/movie.mp4',
        trailerUrl: 'https://media.example/trailer.mp4');
    await seedPlayback(item, progressKey: item.title, position: 7000);
    final platform = FakeVideoPlatform();
    VideoPlayerPlatform.instance = platform;
    await tester.pumpWidget(MaterialApp(
        home: PlayerScreen(contentTitle: item.title, trailer: true)));
    await pumpPlayback(tester);
    expect(platform.sources.values.single.uri, item.trailerUrl);
    expect(platform.seeks, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpPlayback(tester);
    expect(appState.watchProgress(item.title)!.positionMs, 7000);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cambiar el perfil pausa y bloquea la reproducción actual',
      (tester) async {
    const item = CatalogItem(
        id: 'movie',
        title: 'Una película',
        genre: 'Comedia',
        year: 2026,
        videoUrl: 'https://media.example/movie.mp4');
    await seedPlayback(item);
    final platform = FakeVideoPlatform();
    VideoPlayerPlatform.instance = platform;
    await tester
        .pumpWidget(MaterialApp(home: PlayerScreen(contentTitle: item.title)));
    await pumpPlayback(tester);
    await appState.setActiveProfile('Luis');
    await tester.pump();
    expect(find.text('El perfil cambió o ya no tiene acceso a este contenido.'),
        findsOneWidget);
    final play = tester.widget<IconButton>(find
        .byWidgetPredicate(
            (widget) => widget is IconButton && widget.tooltip == 'Reproducir')
        .first);
    expect(play.onPressed, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpPlayback(tester);
  });
  testWidgets(
      'cambiar de perfil también cierra los controles de pantalla completa',
      (tester) async {
    const item = CatalogItem(
        id: 'movie',
        title: 'Una película',
        genre: 'Comedia',
        year: 2026,
        videoUrl: 'https://media.example/movie.mp4');
    await seedPlayback(item);
    VideoPlayerPlatform.instance = FakeVideoPlatform();
    await tester
        .pumpWidget(MaterialApp(home: PlayerScreen(contentTitle: item.title)));
    await pumpPlayback(tester);
    await tester.tap(find.byTooltip('Pantalla completa'));
    await tester.pumpAndSettle();
    expect(find.byType(FullscreenPlayerScreen), findsOneWidget);
    await appState.setActiveProfile('Luis');
    await tester.pumpAndSettle();
    expect(find.byType(FullscreenPlayerScreen), findsNothing);
    expect(find.text('El perfil cambió o ya no tiene acceso a este contenido.'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpPlayback(tester);
    expect(tester.takeException(), isNull);
  });
}
