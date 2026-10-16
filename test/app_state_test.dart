import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_app/state/app_state.dart';

/// Pruebas unitarias de AppState: la lógica de tokens, Mi lista y descargas,
/// sin necesidad de abrir ninguna pantalla.
void main() {
  // AppState usa SharedPreferences; en pruebas se simula con un
  // almacenamiento en memoria para no depender de un dispositivo real.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Tokens', () {
    test('addTokens aumenta el saldo y agrega una entrada al historial', () async {
      final state = AppState();
      await state.load();
      final saldoInicial = state.tokenBalance;

      state.addTokens(50, reason: 'Anuncio visto');

      expect(state.tokenBalance, saldoInicial + 50);
      expect(state.tokenHistory.first['titulo'], 'Anuncio visto');
      expect(state.tokenHistory.first['valor'], '+50');
    });

    test('spendTokens descuenta el saldo cuando alcanza', () async {
      final state = AppState();
      await state.load();
      final saldoInicial = state.tokenBalance;

      final exito = state.spendTokens(100, reason: 'Desbloqueo capítulo');

      expect(exito, true);
      expect(state.tokenBalance, saldoInicial - 100);
    });

    test('spendTokens falla y no descuenta nada si no alcanza el saldo', () async {
      final state = AppState();
      await state.load();
      final saldoInicial = state.tokenBalance;

      final exito = state.spendTokens(saldoInicial + 1, reason: 'Desbloqueo imposible');

      expect(exito, false);
      expect(state.tokenBalance, saldoInicial); // no cambia
    });
  });

  group('Mi lista', () {
    test('toggleMyList agrega y luego quita el mismo título', () async {
      final state = AppState();
      await state.load();
      const titulo = 'Mi serie favorita';

      expect(state.isInMyList(titulo), false);

      state.toggleMyList(titulo);
      expect(state.isInMyList(titulo), true);

      state.toggleMyList(titulo);
      expect(state.isInMyList(titulo), false);
    });
  });

  group('Descargas', () {
    test('downloadContent marca el título como descargado', () async {
      final state = AppState();
      await state.load();
      const titulo = 'Episodio 1';

      expect(state.isDownloaded(titulo), false);

      state.downloadContent(titulo);
      expect(state.isDownloaded(titulo), true);
      expect(state.downloads, contains(titulo));
    });

    test('removeDownload quita el título de la lista', () async {
      final state = AppState();
      await state.load();
      const titulo = 'Episodio 1';

      state.downloadContent(titulo);
      state.removeDownload(titulo);

      expect(state.isDownloaded(titulo), false);
    });
  });

  group('Sesión', () {
    test('login y logout cambian isLoggedIn', () async {
      final state = AppState();
      await state.load();

      expect(state.isLoggedIn, false);

      await state.login();
      expect(state.isLoggedIn, true);

      await state.logout();
      expect(state.isLoggedIn, false);
    });

    test('load() recupera la sesión guardada previamente', () async {
      SharedPreferences.setMockInitialValues({'isLoggedIn': true, 'tokenBalance': 777});

      final state = AppState();
      await state.load();

      expect(state.isLoggedIn, true);
      expect(state.tokenBalance, 777);
    });
  });
}
