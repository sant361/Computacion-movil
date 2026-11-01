import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_app/state/app_state.dart';
import 'package:streaming_app/services/profile_store.dart';

class MemoryProfiles implements ProfileStore {
  final rows = <String, Map<String, ProfileDetails>>{};
  final events = StreamController<void>.broadcast();
  bool offline = false;
  @override
  Stream<List<ProfileDetails>> watch(String uid) async* {
    yield rows[uid]?.values.toList() ?? [];
    await for (final _ in events.stream) {
      yield rows[uid]?.values.toList() ?? [];
    }
  }

  @override
  Future<void> write(String uid, ProfileDetails p) async {
    if (offline) throw StateError('offline');
    final r = rows.putIfAbsent(uid, () => {});
    if ((r[p.name]?.updatedAt ?? -1) < p.updatedAt) r[p.name] = p;
    events.add(null);
  }
}

Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 20));
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('favoritos y valoraciones se separan por perfil y persisten', () async {
    final state = AppState();
    await state.loadProfiles('cuenta');
    state.toggleMyList('Risas en el aire');
    await state.setContentRating('Risas en el aire', true);
    await state.setActiveProfile('Luis');
    expect(state.myListTitles, isEmpty);
    expect(state.ratingFor('Risas en el aire'), isNull);
    await state.setActiveProfile('Ana');
    expect(state.myListTitles, contains('Risas en el aire'));
    expect(state.ratingFor('Risas en el aire'), isTrue);
    final restored = AppState();
    await restored.loadProfiles('cuenta');
    expect(restored.myListTitles, contains('Risas en el aire'));
    await restored.loadProfiles('otra');
    expect(restored.myListTitles, isEmpty);
    state.dispose();
    restored.dispose();
  });
  test('quitar continuar conserva historial y borrar historial lo vacía',
      () async {
    final state = AppState();
    await state.loadProfiles('cuenta');
    await state.saveWatchProgress('Risas en el aire',
        const Duration(seconds: 20), const Duration(seconds: 100),
        scope: state.playbackScope);
    final item = state.catalogItem('Risas en el aire')!;
    expect(state.continueProgress(item), isNotNull);
    await state.removeFromContinueWatching(item.title);
    expect(state.continueProgress(item), isNull);
    expect(state.viewingHistory, isNotEmpty);
    await state.clearViewingHistory();
    expect(state.viewingHistory, isEmpty);
    state.dispose();
  });
  test('PIN derivado y perfil infantil restringen catálogo y gestión', () async {
    final state = AppState();
    await state.loadProfiles('cuenta');
    await state.configureProfile('Ana', pin: '1234', avatar: 'movie');
    expect(state.profileDetails('Ana').pinHash, isNot('1234'));
    expect(await state.verifyProfilePin('Ana', '0000'), isFalse);
    expect(await state.verifyProfilePin('Ana', '1234'), isTrue);
    await state.configureProfile('Kids', isChild: true, maxRating: 'TP');
    await state.setActiveProfile('Kids');
    expect(state.catalog.every((i) => i.rating == 'TP'), isTrue);
    await expectLater(
        state.configureProfile('Kids', isChild: false), throwsStateError);
    await expectLater(state.addProfile('Otro'), throwsStateError);
    await expectLater(
        state.setActiveProfile('Ana', pin: '0000'), throwsStateError);
    await state.setActiveProfile('Ana', pin: '1234');
    expect(state.catalog.any((i) => i.rating == '+18'), isTrue);
    state.dispose();
  });
  test('perfiles y avatares llegan al segundo dispositivo sin cruzar cuentas',
      () async {
    final store = MemoryProfiles();
    final a =
        AppState(profileStore: store, authenticatedUserId: () => 'cuenta');
    final b =
        AppState(profileStore: store, authenticatedUserId: () => 'cuenta');
    final other =
        AppState(profileStore: store, authenticatedUserId: () => 'otra');
    await a.loadProfiles('cuenta');
    await b.loadProfiles('cuenta');
    await other.loadProfiles('otra');
    await tick();
    await a.addProfile('Nuevo');
    await a.configureProfile('Nuevo', avatar: 'star');
    await tick();
    expect(b.profiles, contains('Nuevo'));
    expect(b.profileDetails('Nuevo').avatar, 'star');
    expect(other.profiles, isNot(contains('Nuevo')));
    a.dispose();
    b.dispose();
    other.dispose();
    await store.events.close();
  });
}
