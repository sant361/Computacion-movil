import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_app/services/progress_store.dart';
import 'package:streaming_app/state/app_state.dart';

class MemoryProgressStore implements ProgressStore {
  final records = <String, Map<String, SyncedProgress>>{};
  final events = StreamController<void>.broadcast();
  bool offline = false;
  Completer<void>? firstRead;
  int writes = 0;

  @override
  Stream<List<SyncedProgress>> watch(String userId) async* {
    if (firstRead != null) await firstRead!.future;
    yield records[userId]?.values.toList() ?? [];
    await for (final _ in events.stream) {
      yield records[userId]?.values.toList() ?? [];
    }
  }

  @override
  Future<void> write(String userId, SyncedProgress progress) async {
    if (offline) throw StateError('offline');
    writes++;
    final account = records.putIfAbsent(userId, () => {});
    final key = '${progress.profile}:${progress.title}';
    if ((account[key]?.updatedAt ?? -1) < progress.updatedAt) {
      account[key] = progress;
    }
    events.add(null);
  }
}

Future<void> settleSync() =>
    Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  late MemoryProgressStore store;
  final states = <AppState>[];

  Future<AppState> device(String uid) async {
    final state =
        AppState(progressStore: store, authenticatedUserId: () => uid);
    states.add(state);
    await state.loadProfiles(uid);
    await settleSync();
    return state;
  }

  Future<void> save(AppState state, int seconds) => state.saveWatchProgress(
        'Serie',
        Duration(seconds: seconds),
        const Duration(seconds: 100),
        scope: state.playbackScope,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = MemoryProgressStore();
  });

  tearDown(() async {
    for (final state in states) {
      state.dispose();
    }
    states.clear();
    await store.events.close();
  });

  test('otro dispositivo recibe el avance y se separan cuentas y perfiles',
      () async {
    final first = await device('cuenta');
    final second = await device('cuenta');
    final other = await device('otra');
    await save(first, 30);
    await first.syncWatchProgress();
    await settleSync();
    expect(second.watchProgress('Serie')!.positionMs, 30000);
    expect(other.watchProgress('Serie'), isNull);
    await second.setActiveProfile('Luis');
    expect(second.watchProgress('Serie'), isNull);
    await second.setActiveProfile('Ana');
    expect(second.watchProgress('Serie')!.positionMs, 30000);
  });

  test('el pendiente sobrevive al cierre y se reintenta al recuperar conexión',
      () async {
    final first = await device('cuenta');
    store.offline = true;
    await save(first, 42);
    await first.syncWatchProgress();
    expect(first.progressSyncError, isNotNull);
    first.dispose();
    states.remove(first);
    final restarted = await device('cuenta');
    expect(restarted.watchProgress('Serie')!.positionMs, 42000);
    store.offline = false;
    await restarted.syncWatchProgress();
    await settleSync();
    expect(store.records['cuenta']!['Ana:Serie']!.positionMs, 42000);
    expect(restarted.progressSyncError, isNull);
  });

  test('el progreso viejo no reemplaza al nuevo y se permite retroceder',
      () async {
    final first = await device('cuenta');
    await save(first, 80);
    await first.syncWatchProgress();
    await settleSync();
    final current = store.records['cuenta']!['Ana:Serie']!;
    await store.write(
        'cuenta',
        SyncedProgress(
            profile: 'Ana',
            title: 'Serie',
            positionMs: 10000,
            durationMs: 100000,
            updatedAt: current.updatedAt - 1));
    await settleSync();
    expect(first.watchProgress('Serie')!.positionMs, 80000);
    await save(first, 20);
    await first.syncWatchProgress();
    await settleSync();
    expect(store.records['cuenta']!['Ana:Serie']!.positionMs, 20000);
  });

  test('finalizar y reiniciar se propagan sin resucitar el pendiente',
      () async {
    final first = await device('cuenta');
    final second = await device('cuenta');
    for (final end in [100, 0]) {
      await save(first, 35);
      await first.syncWatchProgress();
      await settleSync();
      expect(second.watchProgress('Serie'), isNotNull);
      await save(first, end);
      await first.syncWatchProgress();
      await settleSync();
      expect(second.watchProgress('Serie'), isNull);
      expect(store.records['cuenta']!['Ana:Serie']!.positionMs, 0);
    }
  });

  test('migra formato local anterior sin pisar progreso remoto', () async {
    SharedPreferences.setMockInitialValues({
      'watchHistory':
          '{"[\\"cuenta\\",\\"Ana\\"]":{"Serie":[10000,100000],"Otra":[20000,100000]}}'
    });
    store.records['cuenta'] = {
      'Ana:Serie': const SyncedProgress(
          profile: 'Ana',
          title: 'Serie',
          positionMs: 65000,
          durationMs: 100000,
          updatedAt: 100)
    };
    final state = await device('cuenta');
    await state.syncWatchProgress();
    await settleSync();
    expect(state.watchProgress('Serie')!.positionMs, 65000);
    expect(store.records['cuenta']!['Ana:Otra']!.positionMs, 20000);
  });

  test(
      'salir cancela la escucha y una cuenta distinta no envía pendientes ajenos',
      () async {
    final state = await device('cuenta');
    await save(state, 25);
    await state.logout();
    await state.loadProfiles('otra');
    await state.syncWatchProgress();
    await settleSync();
    expect(state.watchProgress('Serie'), isNull);
    expect(store.records, isEmpty);
  });

  test('espera la primera lectura antes de elegir el punto de reproducción',
      () async {
    store.firstRead = Completer<void>();
    store.records['cuenta'] = {
      'Ana:Serie': const SyncedProgress(
          profile: 'Ana',
          title: 'Serie',
          positionMs: 70000,
          durationMs: 100000,
          updatedAt: 100)
    };
    final state = await device('cuenta');
    var completed = false;
    final prepared = state.prepareWatchProgress('Serie').then((value) {
      completed = true;
      return value;
    });
    await settleSync();
    expect(completed, isFalse);
    store.firstRead!.complete();
    expect((await prepared)!.positionMs, 70000);
  });

  test('un error de lectura se recupera al reintentar', () async {
    final state = await device('cuenta');
    store.events.addError(StateError('permission-denied'));
    await settleSync();
    expect(state.progressSyncError, isNotNull);
    await state.retryProgressSync();
    await settleSync();
    expect(state.progressSyncError, isNull);
    await save(state, 25);
    await state.syncWatchProgress();
    expect(store.records['cuenta']!['Ana:Serie']!.positionMs, 25000);
  });

  test('valida registros remotos dañados sin detener la lectura', () {
    expect(
        SyncedProgress.fromJson({
          'profile': 'Ana',
          'title': 'Serie',
          'positionMs': -5,
          'durationMs': 100,
          'updatedAt': 1
        }),
        isNull);
    expect(
        SyncedProgress.fromJson({
          'profile': 'Ana',
          'title': 'Serie',
          'positionMs': 100,
          'durationMs': 100,
          'updatedAt': 1
        }),
        isNull);
  });
}
