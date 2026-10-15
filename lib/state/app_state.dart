import 'package:flutter/foundation.dart';

/// Estado compartido simple de la app (sin paquetes externos de estado).
///
/// [appState] es una única instancia global: cualquier pantalla puede leer
/// appState.tokenBalance, y escuchar cambios envolviendo su UI en un
/// ListenableBuilder(listenable: appState, builder: (...) => ...).
class AppState extends ChangeNotifier {
  int _tokenBalance = 1250;
  int get tokenBalance => _tokenBalance;

  final List<Map<String, String>> _tokenHistory = [
    {'titulo': 'Anuncio visto', 'valor': '+50'},
    {'titulo': 'Desbloqueo capítulo 12', 'valor': '-120'},
    {'titulo': 'Juego · Trivia', 'valor': '+80'},
  ];
  List<Map<String, String>> get tokenHistory => List.unmodifiable(_tokenHistory);

  void addTokens(int amount, {required String reason}) {
    _tokenBalance += amount;
    _tokenHistory.insert(0, {'titulo': reason, 'valor': '+$amount'});
    notifyListeners();
  }

  bool spendTokens(int amount, {required String reason}) {
    if (amount > _tokenBalance) return false;
    _tokenBalance -= amount;
    _tokenHistory.insert(0, {'titulo': reason, 'valor': '-$amount'});
    notifyListeners();
    return true;
  }

  // "Mi lista": identifica cada contenido por su título. En una versión con
  // backend real, esto sería el id del contenido en vez del título.
  final Set<String> _myList = {};

  bool isInMyList(String contentTitle) => _myList.contains(contentTitle);

  void toggleMyList(String contentTitle) {
    if (_myList.contains(contentTitle)) {
      _myList.remove(contentTitle);
    } else {
      _myList.add(contentTitle);
    }
    notifyListeners();
  }
}

/// Instancia única compartida por toda la app.
final AppState appState = AppState();
