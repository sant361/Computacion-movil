import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Estado compartido simple de la app (sin paquetes externos de estado).
///
/// [appState] es una única instancia global: cualquier pantalla puede leer
/// appState.tokenBalance, y escuchar cambios envolviendo su UI en un
/// ListenableBuilder(listenable: appState, builder: (...) => ...).
///
/// El saldo de tokens y "Mi lista" se guardan en el almacenamiento local del
/// dispositivo (shared_preferences), así que sobreviven a cerrar la app.
/// El historial de movimientos de tokens NO se guarda (queda solo en memoria)
/// para mantener esto simple; guardarlo sería el siguiente paso natural.
class AppState extends ChangeNotifier {
  static const _tokenBalanceKey = 'tokenBalance';
  static const _myListKey = 'myList';
  static const _isLoggedInKey = 'isLoggedIn';

  SharedPreferences? _prefs;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  int _tokenBalance = 1250;
  int get tokenBalance => _tokenBalance;

  final List<Map<String, String>> _tokenHistory = [
    {'titulo': 'Anuncio visto', 'valor': '+50'},
    {'titulo': 'Desbloqueo capítulo 12', 'valor': '-120'},
    {'titulo': 'Juego · Trivia', 'valor': '+80'},
  ];
  List<Map<String, String>> get tokenHistory => List.unmodifiable(_tokenHistory);

  final Set<String> _myList = {};
  bool isInMyList(String contentTitle) => _myList.contains(contentTitle);

  /// Carga el estado guardado en el dispositivo. Llamar una vez al inicio,
  /// antes de runApp(), para que la app abra ya con los datos reales.
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _tokenBalance = _prefs!.getInt(_tokenBalanceKey) ?? _tokenBalance;
    _isLoggedIn = _prefs!.getBool(_isLoggedInKey) ?? false;
    final savedList = _prefs!.getStringList(_myListKey);
    if (savedList != null) {
      _myList
        ..clear()
        ..addAll(savedList);
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setInt(_tokenBalanceKey, _tokenBalance);
    await prefs.setStringList(_myListKey, _myList.toList());
  }

  /// Marca la sesión como iniciada y lo recuerda en el dispositivo.
  /// TODO: cuando haya backend real, aquí se validarían las credenciales
  /// y se guardaría el token de sesión en vez de solo un booleano.
  Future<void> login() async {
    _isLoggedIn = true;
    notifyListeners();
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    notifyListeners();
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
  }

  void addTokens(int amount, {required String reason}) {
    _tokenBalance += amount;
    _tokenHistory.insert(0, {'titulo': reason, 'valor': '+$amount'});
    notifyListeners();
    _persist();
  }

  bool spendTokens(int amount, {required String reason}) {
    if (amount > _tokenBalance) return false;
    _tokenBalance -= amount;
    _tokenHistory.insert(0, {'titulo': reason, 'valor': '-$amount'});
    notifyListeners();
    _persist();
    return true;
  }

  void toggleMyList(String contentTitle) {
    if (_myList.contains(contentTitle)) {
      _myList.remove(contentTitle);
    } else {
      _myList.add(contentTitle);
    }
    notifyListeners();
    _persist();
  }
}

/// Instancia única compartida por toda la app.
final AppState appState = AppState();
