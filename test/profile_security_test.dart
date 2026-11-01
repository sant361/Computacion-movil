import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_app/state/app_state.dart';
import 'package:streaming_app/data/catalog_item.dart';
import 'package:streaming_app/services/profile_store.dart';
import 'package:streaming_app/services/catalog_store.dart';

class ReviewProfiles implements ProfileStore {
  final records = <String, ProfileDetails>{};
  final changes = StreamController<void>.broadcast();
  @override
  Stream<List<ProfileDetails>> watch(String uid) async* {
    yield records.values.toList();
    await for (final _ in changes.stream) {
      yield records.values.toList();
    }
  }

  @override
  Future<void> write(String uid, ProfileDetails profile) async {
    if ((records[profile.name]?.updatedAt ?? -1) < profile.updatedAt) {
      records[profile.name] = profile;
      changes.add(null);
    }
  }
}

class ReviewCatalog implements CatalogStore {
  final items = <CatalogItem>[];
  @override
  Future<List<CatalogItem>> load() async => List.of(items);
  @override
  Future<CatalogItem> add(CatalogItem item) => throw UnimplementedError();
  @override
  Future<void> update(CatalogItem item) => throw UnimplementedError();
  @override
  Future<void> delete(CatalogItem item) => throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> statistics() async => [];
}

Future<void> settleProfiles() =>
    Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'un adulto bloqueado no crea otro perfil ni cambia controles para saltar el PIN',
      () async {
    const protected =
        ProfileDetails(name: 'Ana', pinHash: 'hash-protegido', pinSalt: 'salt');
    SharedPreferences.setMockInitialValues({
      'profiles:cuenta': ['Ana', 'Luis', 'Kids'],
      'activeProfile:cuenta': 'Ana',
      'profileDetails:cuenta': jsonEncode({'Ana': protected.toJson()}),
    });
    final state = AppState();
    addTearDown(state.dispose);
    await state.loadProfiles('cuenta');
    expect(state.profileLocked, isTrue);
    expect(state.catalog, isEmpty);
    await expectLater(state.addProfile('Sin PIN'), throwsStateError);
    await expectLater(state.removeProfile('Luis'), throwsStateError);
    await expectLater(
        state.saveParentalSettings(
            maxRating: '+18',
            restrictByProfile: false,
            blockPurchases: false,
            pin: ''),
        throwsStateError);
    expect(state.profiles, isNot(contains('Sin PIN')));
    expect(state.profiles, contains('Luis'));
  });

  test(
      'no elimina el último adulto ni lo convierte en infantil sin recuperación',
      () async {
    SharedPreferences.setMockInitialValues({
      'profiles:cuenta': ['Ana', 'Kids'],
      'activeProfile:cuenta': 'Ana'
    });
    final state = AppState();
    addTearDown(state.dispose);
    await state.loadProfiles('cuenta');
    await expectLater(state.removeProfile('Ana'), throwsStateError);
    await expectLater(
        state.configureProfile('Ana', isChild: true), throwsStateError);
    expect(state.activeProfile, 'Ana');
    expect(state.profileDetails('Ana').isChild, isFalse);
    expect(state.profiles, contains('Ana'));
  });

  test(
      'una eliminación remota no abre un adulto sin PIN desde un perfil infantil',
      () async {
    const ana = ProfileDetails(name: 'Ana');
    const luis = ProfileDetails(
        name: 'Luis', pinHash: 'hash-protegido', pinSalt: 'salt');
    const kids = ProfileDetails(name: 'Kids', isChild: true, maxRating: 'TP');
    SharedPreferences.setMockInitialValues({
      'profiles:cuenta': ['Ana', 'Luis', 'Kids'],
      'activeProfile:cuenta': 'Ana',
      'profileDetails:cuenta': jsonEncode({
        for (final p in [ana, luis, kids]) p.name: p.toJson()
      }),
    });
    final store = ReviewProfiles()
      ..records.addAll({
        for (final p in [ana, luis, kids]) p.name: p
      });
    final state =
        AppState(profileStore: store, authenticatedUserId: () => 'cuenta');
    addTearDown(() async {
      state.dispose();
      await store.changes.close();
    });
    await state.loadProfiles('cuenta');
    await settleProfiles();
    await state.setActiveProfile('Kids');
    expect(state.profileDetails(state.activeProfile!).isChild, isTrue);
    store.records['Kids'] = const ProfileDetails(
        name: 'Kids',
        isChild: true,
        maxRating: 'TP',
        deleted: true,
        updatedAt: 100);
    store.changes.add(null);
    await settleProfiles();
    expect(state.profileLocked, isTrue);
    expect(state.activeProfile, isNot('Ana'));
    expect(state.catalog, isEmpty);
    await expectLater(state.setActiveProfile('Ana'), throwsStateError);
    await state.loadProfiles('cuenta');
    await settleProfiles();
    expect(state.catalog, isEmpty);
    await expectLater(state.setActiveProfile('Ana'), throwsStateError);
  });

  test(
      'cargar catálogo antes de perfiles no copia notificaciones entre cuentas',
      () async {
    const baseline = CatalogItem(
        id: 'base', title: 'Catálogo inicial', genre: 'Comedia', year: 2024);
    const releaseA = CatalogItem(
        id: 'release-a', title: 'Estreno A', genre: 'Comedia', year: 2025);
    const releaseB = CatalogItem(
        id: 'release-b', title: 'Estreno B', genre: 'Comedia', year: 2026);
    final store = ReviewCatalog()..items.add(baseline);
    var uid = 'cuenta-a';
    final state = AppState(catalogStore: store, authenticatedUserId: () => uid);
    addTearDown(state.dispose);
    await state.loadProfiles(uid);
    await state.refreshCatalog();
    store.items.add(releaseA);
    await state.refreshCatalog();
    expect(state.notifications.map((n) => n.contentTitle), ['Estreno A']);
    await state.setNotificationsEnabled(false);
    await state.logout();
    uid = 'cuenta-b';
    await state.refreshCatalog();
    expect(state.notificationsEnabled, isTrue);
    expect(state.notifications, isEmpty);
    await state.loadProfiles(uid);
    store.items.add(releaseB);
    await state.refreshCatalog();
    expect(state.notifications.map((n) => n.contentTitle), ['Estreno B']);
    await state.logout();
    uid = 'cuenta-a';
    await state.refreshCatalog();
    await state.loadProfiles(uid);
    expect(state.notificationsEnabled, isFalse);
    await state.setNotificationsEnabled(true);
    expect(state.notifications.map((n) => n.contentTitle), ['Estreno A']);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('releaseNotificationsEnabled:cuenta-b'), isTrue);
  });
}
