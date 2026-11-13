import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_app/data/catalog_item.dart';
import 'package:streaming_app/state/app_state.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Clasificación por edad', () {
    CatalogItem item(String genre, {String? age}) => CatalogItem(
        title: 'T', genre: genre, year: 2020, ageRating: age);

    test('se deduce del género cuando no hay clasificación', () {
      expect(item('Infantil').rating, 'TP');
      expect(item('Comedia').rating, 'TP');
      expect(item('Romance').rating, '+14');
      expect(item('Acción').rating, '+14');
      expect(item('Suspenso').rating, '+18');
    });

    test('una clasificación explícita tiene prioridad y una inválida es +18', () {
      expect(item('Suspenso', age: 'TP').rating, 'TP');
      expect(item('Infantil', age: 'otra').rating, '+18');
    });
  });

  group('Anuncios', () {
    test('el contador diario sube de uno en uno por cuenta', () async {
      final state = AppState();
      await state.load();
      expect(await state.adsWatchedToday('a'), 0);
      await state.recordAdWatched('a');
      await state.recordAdWatched('a');
      expect(await state.adsWatchedToday('a'), 2);
      expect(await state.adsWatchedToday('b'), 0);
      expect(AppState.dailyAdLimit, 4);
    });
  });

  group('Reglas de Firestore', () {
    final rules = File('firebase/firestore.rules').readAsStringSync();

    test('el catálogo solo se escribe siendo administrador', () {
      final block = rules.split('match /catalog/')[1].split('match /users')[0];
      expect(block, contains('allow create, update: if admin()'));
      expect(block, contains('allow delete: if admin()'));
    });

    test('cada colección de la cuenta está limitada a su dueño', () {
      for (final path in [
        'match /users/{uid} {',
        'match /subscriptions/{uid} {',
        'match /users/{uid}/settings/{docId} {',
      ]) {
        expect(rules, contains(path));
      }
      expect(rules, isNot(contains('allow read, write: if true')));
    });
  });
}
