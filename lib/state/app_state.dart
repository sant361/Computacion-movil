import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/catalog_item.dart';

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
  static const _downloadsKey = 'downloads';
  static const _languageCodeKey = 'languageCode';
  static const _supportedLanguages = {'es', 'en', 'fr'};

  SharedPreferences? _prefs;

  String _languageCode = 'es';
  String get languageCode => _languageCode;

  String? _paymentUserId;
  List<Map<String, String>> _paymentMethods = [];
  List<Map<String, String>> get paymentMethods => List.unmodifiable(_paymentMethods);

  // Mientras se carga desde Firestore (o si falla la conexión), la app
  // muestra este catálogo de muestra para que nunca se vea vacía.
  List<CatalogItem> _catalog = sampleCatalog;
  /// Catálogo visible: ya sin lo que supere la clasificación máxima del
  /// control parental.
  List<CatalogItem> get catalog {
    final limit = parentalRatings.indexOf(_parentalMaxRating);
    return List.unmodifiable(
      _catalog.where((item) => parentalRatings.indexOf(item.rating) <= limit),
    );
  }

  // Administrador: existe un documento admins/{uid} en Firestore para esta cuenta.
  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  /// Consulta si la cuenta es administradora. Si falla (sin conexión, sin
  /// permisos), se asume que NO lo es.
  Future<void> loadAdminStatus(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('admins').doc(userId).get();
      _isAdmin = doc.exists;
    } catch (_) {
      _isAdmin = false;
    }
    notifyListeners();
  }

  // Control parental (se guarda por cuenta, igual que los perfiles).
  String? _parentalUserId;
  String _parentalMaxRating = '+18';
  bool _parentalRestrictByProfile = true;
  bool _parentalBlockPurchases = false;
  String _parentalPin = '';
  String get parentalMaxRating => _parentalMaxRating;
  bool get parentalRestrictByProfile => _parentalRestrictByProfile;
  bool get parentalBlockPurchases => _parentalBlockPurchases;
  String get parentalPin => _parentalPin;

  String? _profileUserId;
  List<String> _profiles = [];
  List<String> get profiles => List.unmodifiable(_profiles);
  String? _activeProfile;
  String? get activeProfile => _activeProfile;

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

  // Descargas: por simplicidad se marcan como completas al instante
  // (no hay una descarga real en progreso, es solo para la demo).
  final Set<String> _downloads = {};
  List<String> get downloads => List.unmodifiable(_downloads);
  bool isDownloaded(String contentTitle) => _downloads.contains(contentTitle);

  /// Carga el estado guardado en el dispositivo. Llamar una vez al inicio,
  /// antes de runApp(), para que la app abra ya con los datos reales.
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _tokenBalance = _prefs!.getInt(_tokenBalanceKey) ?? _tokenBalance;
    _isLoggedIn = _prefs!.getBool(_isLoggedInKey) ?? false;
    _languageCode = _prefs!.getString(_languageCodeKey) ?? _languageCode;
    final savedList = _prefs!.getStringList(_myListKey);
    if (savedList != null) {
      _myList
        ..clear()
        ..addAll(savedList);
    }
    final savedDownloads = _prefs!.getStringList(_downloadsKey);
    if (savedDownloads != null) {
      _downloads
        ..clear()
        ..addAll(savedDownloads);
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setInt(_tokenBalanceKey, _tokenBalance);
    await prefs.setStringList(_myListKey, _myList.toList());
    await prefs.setStringList(_downloadsKey, _downloads.toList());
  }

  void downloadContent(String contentTitle) {
    _downloads.add(contentTitle);
    notifyListeners();
    _persist();
  }

  void removeDownload(String contentTitle) {
    _downloads.remove(contentTitle);
    notifyListeners();
    _persist();
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
    _paymentUserId = null;
    _paymentMethods = [];
    _profileUserId = null;
    _profiles = [];
    _activeProfile = null;
    _isAdmin = false;
    _parentalUserId = null;
    _parentalMaxRating = '+18';
    _parentalRestrictByProfile = true;
    _parentalBlockPurchases = false;
    _parentalPin = '';
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

  /// Cambia el idioma de la app si [code] es uno de los soportados
  /// ('es', 'en', 'fr'). Un código desconocido se ignora y se conserva
  /// el idioma actual.
  Future<void> setLanguage(String code) async {
    if (!_supportedLanguages.contains(code)) return;
    _languageCode = code;
    notifyListeners();
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, code);
  }

  String _paymentMethodsKey(String userId) => 'paymentMethods:$userId';

  /// Carga los métodos de pago guardados para [userId]. Se guardan por
  /// cuenta (nunca el número completo ni el CVV, solo los últimos 4
  /// dígitos) para que cada usuario vea solo los suyos.
  Future<void> loadPaymentMethods(String userId) async {
    _paymentUserId = userId;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final raw = prefs.getString(_paymentMethodsKey(userId));
    if (raw == null) {
      _paymentMethods = [];
    } else {
      final decoded = jsonDecode(raw) as List;
      _paymentMethods = decoded
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
    }
    notifyListeners();
  }

  Future<void> _persistPaymentMethods() async {
    final userId = _paymentUserId;
    if (userId == null) return;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(_paymentMethodsKey(userId), jsonEncode(_paymentMethods));
  }

  /// Agrega un método de pago nuevo. Solo se guardan los últimos 4
  /// dígitos de la tarjeta, nunca el número completo ni el CVV.
  Future<void> addPaymentMethod({
    required String last4,
    required String brand,
    required String expiry,
    required String holder,
    required bool isDefault,
  }) async {
    if (isDefault) {
      for (final m in _paymentMethods) {
        m['principal'] = 'false';
      }
    }
    final id = '${DateTime.now().microsecondsSinceEpoch}_${_paymentMethods.length}';
    _paymentMethods.add({
      'id': id,
      'nombre': '$brand •••• $last4',
      'detalle': 'Vence $expiry',
      'last4': last4,
      'brand': brand,
      'expiry': expiry,
      'holder': holder,
      'principal': (isDefault || _paymentMethods.isEmpty) ? 'true' : 'false',
    });
    notifyListeners();
    await _persistPaymentMethods();
  }

  /// Marca [id] como el método principal y desmarca los demás.
  Future<void> setDefaultPaymentMethod(String id) async {
    for (final m in _paymentMethods) {
      m['principal'] = (m['id'] == id) ? 'true' : 'false';
    }
    notifyListeners();
    await _persistPaymentMethods();
  }

  /// Elimina el método [id]. Si era el principal y quedan otros métodos,
  /// el primero que queda pasa a ser el nuevo principal.
  Future<void> removePaymentMethod(String id) async {
    final removed = _paymentMethods.firstWhere((m) => m['id'] == id, orElse: () => <String, String>{});
    final wasDefault = removed['principal'] == 'true';
    _paymentMethods.removeWhere((m) => m['id'] == id);
    if (wasDefault && _paymentMethods.isNotEmpty) {
      _paymentMethods.first['principal'] = 'true';
    }
    notifyListeners();
    await _persistPaymentMethods();
  }

  /// Carga el catálogo desde la colección 'catalog' de Firestore.
  ///
  /// La primera vez que alguien abre la app con la base de datos vacía,
  /// sube el catálogo de muestra a Firestore (así queda ahí para poder
  /// editarlo luego desde la consola de Firebase, sin tocar código). Si
  /// algo falla (sin internet, reglas de Firestore, etc.) se queda
  /// mostrando el catálogo de muestra local en vez de dejar la app vacía.
  /// Agrega un contenido nuevo al catálogo (Firestore) y lo muestra de
  /// inmediato en Inicio y Búsqueda. Lanza un error si no se pudo guardar.
  Future<void> addCatalogItem(CatalogItem item) async {
    await FirebaseFirestore.instance.collection('catalog').add({
      'title': item.title,
      'genre': item.genre,
      'year': item.year,
      'language': item.language,
      'durationMinutes': item.durationMinutes,
    }).timeout(const Duration(seconds: 10));
    _catalog = [..._catalog, item];
    notifyListeners();
  }

  Future<void> loadCatalogFromFirestore() async {
    try {
      final collection = FirebaseFirestore.instance.collection('catalog');
      final snapshot = await collection.get();
      if (snapshot.docs.isEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final item in sampleCatalog) {
          batch.set(collection.doc(), {
            'title': item.title,
            'genre': item.genre,
            'year': item.year,
            'language': item.language,
            'durationMinutes': item.durationMinutes,
          });
        }
        await batch.commit();
        _catalog = sampleCatalog;
      } else {
        // Si el catálogo se sembró antes de agregar idioma/duración,
        // a los documentos viejos les completamos esos campos aquí
        // mismo (una sola vez) para que el filtro funcione con todo.
        final backfill = FirebaseFirestore.instance.batch();
        var needsBackfill = false;
        _catalog = snapshot.docs.asMap().entries.map((entry) {
          final index = entry.key;
          final doc = entry.value;
          final data = doc.data();
          final genre = data['genre'] as String? ?? '';
          var language = data['language'] as String?;
          var duration = (data['durationMinutes'] as num?)?.toInt();
          if (language == null || duration == null) {
            language ??= _defaultLanguageFor(index);
            duration ??= _defaultDurationFor(genre, index);
            backfill.update(doc.reference, {'language': language, 'durationMinutes': duration});
            needsBackfill = true;
          }
          return CatalogItem(
            title: data['title'] as String? ?? '',
            genre: genre,
            year: (data['year'] as num?)?.toInt() ?? 0,
            language: language,
            durationMinutes: duration,
          );
        }).toList();
        if (needsBackfill) {
          await backfill.commit();
        }
      }
      notifyListeners();
    } catch (_) {
      // Sin conexión o sin permisos: se mantiene el catálogo de muestra
      // local que ya estaba mostrando la app.
    }
  }

  static const _languageCycle = ['Español', 'Inglés', 'Francés'];
  static const _durationRangeByGenre = {
    'Comedia': [85, 100],
    'Suspenso': [105, 130],
    'Acción': [100, 135],
    'Infantil': [45, 65],
    'Romance': [90, 110],
  };

  String _defaultLanguageFor(int index) => _languageCycle[index % _languageCycle.length];

  int _defaultDurationFor(String genre, int index) {
    final range = _durationRangeByGenre[genre] ?? [80, 110];
    return range[0] + ((index * 7) % (range[1] - range[0] + 1));
  }

  String _profilesKey(String userId) => 'profiles:$userId';
  String _activeProfileKey(String userId) => 'activeProfile:$userId';

  /// Carga los perfiles guardados para [userId] (y cuál queda activo).
  /// Si es la primera vez, crea los 3 perfiles de muestra de siempre
  /// para que la pantalla no empiece vacía.
  Future<void> loadProfiles(String userId) async {
    _profileUserId = userId;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    _profiles = prefs.getStringList(_profilesKey(userId)) ?? ['Ana', 'Luis', 'Kids'];
    _activeProfile = prefs.getString(_activeProfileKey(userId)) ??
        (_profiles.isNotEmpty ? _profiles.first : null);
    notifyListeners();
    await _persistProfiles();
  }

  String _parentalKey(String userId) => 'parental:$userId';

  /// Carga la configuración de control parental de esta cuenta.
  Future<void> loadParentalSettings(String userId) async {
    _parentalUserId = userId;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final raw = prefs.getString(_parentalKey(userId));
    _parentalMaxRating = '+18';
    _parentalRestrictByProfile = true;
    _parentalBlockPurchases = false;
    _parentalPin = '';
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final rating = data['maxRating'] as String?;
        if (rating != null && parentalRatings.contains(rating)) {
          _parentalMaxRating = rating;
        }
        _parentalRestrictByProfile = data['restrictByProfile'] as bool? ?? true;
        _parentalBlockPurchases = data['blockPurchases'] as bool? ?? false;
        _parentalPin = data['pin'] as String? ?? '';
      } catch (_) {
        // Un dato guardado dañado no debe impedir abrir la app.
      }
    }
    notifyListeners();
  }

  /// Guarda la configuración de control parental y la aplica de inmediato.
  Future<void> saveParentalSettings({
    required String maxRating,
    required bool restrictByProfile,
    required bool blockPurchases,
    required String pin,
  }) async {
    _parentalMaxRating = maxRating;
    _parentalRestrictByProfile = restrictByProfile;
    _parentalBlockPurchases = blockPurchases;
    _parentalPin = pin;
    notifyListeners();
    final userId = _parentalUserId;
    if (userId == null) return;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(
      _parentalKey(userId),
      jsonEncode({
        'maxRating': maxRating,
        'restrictByProfile': restrictByProfile,
        'blockPurchases': blockPurchases,
        'pin': pin,
      }),
    );
  }

  /// Máximo de anuncios que se pueden ver por día para ganar tokens.
  static const dailyAdLimit = 4;

  String _adsKey(String userId) {
    final now = DateTime.now();
    final day = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'adsWatched:$userId:$day';
  }

  /// Cuántos anuncios completó esta cuenta hoy.
  Future<int> adsWatchedToday(String userId) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    return prefs.getInt(_adsKey(userId)) ?? 0;
  }

  /// Suma un anuncio completado al contador de hoy.
  Future<void> recordAdWatched(String userId) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final key = _adsKey(userId);
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + 1);
  }

  Future<void> _persistProfiles() async {
    final userId = _profileUserId;
    if (userId == null) return;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setStringList(_profilesKey(userId), _profiles);
    final active = _activeProfile;
    if (active != null) {
      await prefs.setString(_activeProfileKey(userId), active);
    }
  }

  /// Marca [name] como el perfil que se está usando ahora mismo.
  Future<void> setActiveProfile(String name) async {
    if (!_profiles.contains(name)) return;
    _activeProfile = name;
    notifyListeners();
    await _persistProfiles();
  }

  /// Crea un perfil nuevo con [name] (se ignora si está vacío o repetido).
  Future<void> addProfile(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _profiles.contains(trimmed)) return;
    _profiles.add(trimmed);
    notifyListeners();
    await _persistProfiles();
  }

  /// Elimina el perfil [name]. Si era el activo, el primero que quede
  /// pasa a ser el nuevo activo.
  Future<void> removeProfile(String name) async {
    _profiles.remove(name);
    if (_activeProfile == name) {
      _activeProfile = _profiles.isNotEmpty ? _profiles.first : null;
    }
    notifyListeners();
    await _persistProfiles();
  }
}

/// Instancia única compartida por toda la app.
final AppState appState = AppState();
