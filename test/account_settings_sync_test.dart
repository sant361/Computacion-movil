import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_app/state/app_state.dart';

/// Sin Firebase iniciado (como en las pruebas) la sincronización no debe
/// fallar ni cambiar los datos locales.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('syncAccountSettings sin Firebase conserva el saldo local', () async {
    final state = AppState();
    await state.load();
    final saldo = state.tokenBalance;
    await state.syncAccountSettings('usuario-prueba');
    expect(state.tokenBalance, saldo);
  });

  test('addTokens sigue funcionando sin Firebase', () async {
    final state = AppState();
    await state.load();
    final saldo = state.tokenBalance;
    state.addTokens(10, reason: 'Prueba');
    expect(state.tokenBalance, saldo + 10);
  });
}
