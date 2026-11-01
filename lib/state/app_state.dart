import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/catalog_item.dart';
import '../services/progress_store.dart';
import '../services/catalog_store.dart';

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
  AppState(
      {ProgressStore? progressStore,
      CatalogStore? catalogStore,
      Future<bool> Function(String)? adminStatus,
      String? Function()? authenticatedUserId})
      : _catalogStore = catalogStore ?? FirestoreCatalogStore(),
        _adminStatus = adminStatus,
        _progressStore = progressStore ?? FirestoreProgressStore(),
        _authenticatedUserId = authenticatedUserId ?? _firebaseUserId;

  static String? _firebaseUserId() =>
      Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid;

  final ProgressStore _progressStore;
  final String? Function() _authenticatedUserId;
  StreamSubscription<List<SyncedProgress>>? _progressSubscription;
  Timer? _syncTimer;
  final Map<String, Set<String>> _pendingProgress = {};
  bool _syncReady = false;
  Completer<void>? _firstProgressSnapshot;
  bool _flushingProgress = false;
  int _syncGeneration = 0;
  String? _progressSyncError;
  String? get progressSyncError => _progressSyncError;

  Future<void> _persistWatchHistory() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(
        'watchHistory',
        jsonEncode(_watchHistory.map(
          (scope, entries) => MapEntry(
              scope,
              entries.map((title, p) =>
                  MapEntry(title, [p.positionMs, p.durationMs, p.updatedAt]))),
        )));
    await prefs.setString(
        'viewedTitles',
        jsonEncode(_viewedTitles.map(
          (scope, titles) => MapEntry(scope, titles.toList()),
        )));
    await prefs.setString(
        'pendingWatchProgress',
        jsonEncode(_pendingProgress.map(
          (scope, titles) => MapEntry(scope, titles.toList()),
        )));
  }

  void _stopProgressSync() {
    _syncGeneration++;
    _progressSubscription?.cancel();
    _progressSubscription = null;
    _syncTimer?.cancel();
    _syncReady = false;
    if (_firstProgressSnapshot?.isCompleted == false) {
      _firstProgressSnapshot!.complete();
    }
    _firstProgressSnapshot = null;
    _progressSyncError = null;
  }

  void _startProgressSync() {
    _stopProgressSync();
    final uid = _profileUserId;
    if (uid == null || uid != _authenticatedUserId()) return;
    final generation = _syncGeneration;
    _firstProgressSnapshot = Completer<void>();
    _progressSubscription = _progressStore.watch(uid).listen((records) {
      if (generation != _syncGeneration || uid != _authenticatedUserId()) {
        return;
      }
      for (final record in records) {
        final scope = jsonEncode([uid, record.profile]);
        final history = _watchHistory.putIfAbsent(scope, () => {});
        final local = history[record.title];
        if (local == null || record.updatedAt >= local.updatedAt) {
          _rememberViewed(scope, record.title, record.positionMs);
          history[record.title] = WatchProgress(
              record.positionMs, record.durationMs, record.updatedAt);
          _pendingProgress[scope]?.remove(record.title);
        }
      }
      // Migra historiales anteriores sin reemplazar datos ya existentes en nube.
      for (final entry in _watchHistory.entries) {
        if ((jsonDecode(entry.key) as List).first != uid) continue;
        for (final title in entry.value.keys) {
          if (entry.value[title]!.updatedAt == 0) {
            final legacy = entry.value[title]!;
            entry.value[title] =
                WatchProgress(legacy.positionMs, legacy.durationMs, 1);
            _pendingProgress.putIfAbsent(entry.key, () => {}).add(title);
          }
        }
      }
      _syncReady = true;
      if (_firstProgressSnapshot?.isCompleted == false) {
        _firstProgressSnapshot!.complete();
      }
      _progressSyncError = null;
      notifyListeners();
      unawaited(_persistWatchHistory().catchError((Object error) {
        if (generation != _syncGeneration) return;
        _progressSyncError =
            'No se pudo guardar el progreso en este dispositivo.';
        notifyListeners();
      }));
      unawaited(syncWatchProgress());
    }, onError: (Object error) {
      if (generation != _syncGeneration) return;
      _syncReady = false;
      if (_firstProgressSnapshot?.isCompleted == false) {
        _firstProgressSnapshot!.complete();
      }
      _progressSyncError = 'No se pudo sincronizar el progreso.';
      notifyListeners();
    });
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_syncReady) {
        _startProgressSync();
      } else {
        unawaited(syncWatchProgress());
      }
    });
  }

  Future<WatchProgress?> prepareWatchProgress(String title) async {
    final first = _firstProgressSnapshot;
    if (!_syncReady && first != null) {
      try {
        await first.future.timeout(const Duration(seconds: 3));
      } on TimeoutException {
        // Sin conexión, permite reproducir usando el progreso local.
      }
    }
    return watchProgress(title);
  }

  Future<void> retryProgressSync() async {
    _startProgressSync();
  }

  Future<void> syncWatchProgress() async {
    final uid = _profileUserId;
    if (!_syncReady ||
        _flushingProgress ||
        uid == null ||
        uid != _authenticatedUserId()) {
      return;
    }
    _flushingProgress = true;
    final generation = _syncGeneration;
    try {
      final work = _pendingProgress.entries
          .expand(
              (entry) => entry.value.map((title) => MapEntry(entry.key, title)))
          .toList();
      for (final entry in work) {
        if (generation != _syncGeneration || uid != _authenticatedUserId()) {
          return;
        }
        final scope = jsonDecode(entry.key) as List;
        if (scope[0] != uid || scope[1] is! String) continue;
        final progress = _watchHistory[entry.key]?[entry.value];
        if (progress == null) continue;
        await _progressStore.write(
            uid,
            SyncedProgress(
                profile: scope[1] as String,
                title: entry.value,
                positionMs: progress.positionMs,
                durationMs: progress.durationMs,
                updatedAt: progress.updatedAt));
        if (generation != _syncGeneration) return;
        if (identical(_watchHistory[entry.key]?[entry.value], progress)) {
          _pendingProgress[entry.key]?.remove(entry.value);
        }
      }
      if (generation != _syncGeneration) return;
      _progressSyncError = null;
      await _persistWatchHistory();
    } catch (_) {
      if (generation == _syncGeneration) {
        _progressSyncError =
            'Progreso guardado en este dispositivo. Sincronización pendiente.';
      }
    } finally {
      _flushingProgress = false;
      if (generation == _syncGeneration) notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopProgressSync();
    _catalogTimer?.cancel();
    super.dispose();
  }

  final CatalogStore _catalogStore;
  final Future<bool> Function(String)? _adminStatus;
  Timer? _catalogTimer;

  static const _tokenBalanceKey = 'tokenBalance';
  static const _myListKey = 'myList';
  static const _isLoggedInKey = 'isLoggedIn';
  static const _downloadsKey = 'downloads';
  static const _languageCodeKey = 'languageCode';
  static const _supportedLanguages = {'es', 'en', 'fr'};

  SharedPreferences? _prefs;
  final Map<String, Map<String, WatchProgress>> _watchHistory = {};
  final Map<String, Set<String>> _viewedTitles = {};

  bool get hasViewingHistory => _catalog
      .any((item) => (_viewedTitles[playbackScope] ?? {}).contains(item.title));

  List<CatalogItem> get recommendations {
    final viewed = _viewedTitles[playbackScope] ?? <String>{};
    final genres = <String, int>{};
    final titles = {for (final item in _catalog) item.title: item.genre};
    for (final title in viewed) {
      final genre = titles[title];
      if (genre != null) genres[genre] = (genres[genre] ?? 0) + 1;
    }
    final candidates = {
      for (final item in catalog)
        if (!viewed.contains(item.title) && watchProgress(item.title) == null)
          item.title: item,
    }.values.toList();
    candidates.sort((a, b) {
      final preference = (genres[b.genre] ?? 0).compareTo(genres[a.genre] ?? 0);
      if (preference != 0) return preference;
      final year = b.year.compareTo(a.year);
      return year != 0 ? year : a.title.compareTo(b.title);
    });
    return List.unmodifiable(candidates.take(8));
  }

  void _rememberViewed(String scope, String title, int positionMs) {
    if (positionMs >= 1000) {
      _viewedTitles.putIfAbsent(scope, () => {}).add(title);
    }
  }

  String get playbackScope => jsonEncode([_profileUserId, _activeProfile]);

  WatchProgress? watchProgress(String title) {
    final progress = _watchHistory[playbackScope]?[title];
    return progress != null && progress.positionMs > 0 ? progress : null;
  }

  Future<void> saveWatchProgress(
    String title,
    Duration position,
    Duration duration, {
    required String scope,
  }) async {
    if (duration.inMilliseconds <= 0) return;
    final history = _watchHistory.putIfAbsent(scope, () => {});
    final milliseconds =
        position.inMilliseconds.clamp(0, duration.inMilliseconds);
    _rememberViewed(scope, title, milliseconds);
    final previous = history[title]?.updatedAt ?? 0;
    final now = DateTime.now().microsecondsSinceEpoch;
    final updated = now > previous ? now : previous + 1;
    history[title] = WatchProgress(
        milliseconds >= duration.inMilliseconds - 250 ? 0 : milliseconds,
        duration.inMilliseconds,
        updated);
    _pendingProgress.putIfAbsent(scope, () => {}).add(title);
    notifyListeners();
    await _persistWatchHistory();
  }

  void _loadWatchHistory(SharedPreferences prefs) {
    _watchHistory.clear();
    _pendingProgress.clear();
    _viewedTitles.clear();
    try {
      final viewed = jsonDecode(prefs.getString('viewedTitles') ?? '{}') as Map;
      for (final entry in viewed.entries) {
        _viewedTitles[entry.key as String] =
            (entry.value as List).cast<String>().toSet();
      }
    } catch (_) {
      _viewedTitles.clear();
    }
    try {
      final pending =
          jsonDecode(prefs.getString('pendingWatchProgress') ?? '{}') as Map;
      for (final entry in pending.entries) {
        _pendingProgress[entry.key as String] =
            (entry.value as List).cast<String>().toSet();
      }
      final scopes = jsonDecode(prefs.getString('watchHistory') ?? '{}') as Map;
      for (final entry in scopes.entries) {
        final history = <String, WatchProgress>{};
        for (final item in (entry.value as Map).entries) {
          final values = item.value as List;
          final position = values[0] as int;
          final duration = values[1] as int;
          _rememberViewed(entry.key as String, item.key as String, position);
          if (position >= 0 && duration > position) {
            history[item.key as String] = WatchProgress(
                position, duration, values.length > 2 ? values[2] as int : 0);
          }
        }
        _watchHistory[entry.key as String] = history;
      }
    } catch (_) {
      _watchHistory.clear();
    }
  }

  String _languageCode = 'es';
  String get languageCode => _languageCode;

  String? _paymentUserId;
  List<Map<String, String>> _paymentMethods = [];
  List<Map<String, String>> get paymentMethods =>
      List.unmodifiable(_paymentMethods);

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
      if (_adminStatus != null) {
        _isAdmin = await _adminStatus!(userId);
        notifyListeners();
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(userId)
          .get();
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
  List<Map<String, String>> get tokenHistory =>
      List.unmodifiable(_tokenHistory);

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
    _restoreCatalogCache(_prefs!);
    _loadWatchHistory(_prefs!);
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
    _stopProgressSync();
    _catalogTimer?.cancel();
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
      _paymentMethods =
          decoded.map((e) => Map<String, String>.from(e as Map)).toList();
    }
    notifyListeners();
  }

  Future<void> _persistPaymentMethods() async {
    final userId = _paymentUserId;
    if (userId == null) return;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(
        _paymentMethodsKey(userId), jsonEncode(_paymentMethods));
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
    final id =
        '${DateTime.now().microsecondsSinceEpoch}_${_paymentMethods.length}';
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
    final removed = _paymentMethods.firstWhere((m) => m['id'] == id,
        orElse: () => <String, String>{});
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

  CatalogItem? catalogItem(String key) {
    for (final item in catalog) {
      if (item.title == key ||
          (item.id.isNotEmpty && item.id == key) ||
          item.episodes.any((e) => e.progressKey(item.title) == key)) {
        return item;
      }
    }
    return null;
  }

  Future<void> addCatalogItem(CatalogItem item) async {
    if (!isAdmin) {
      throw StateError('Solo un administrador puede guardar contenido.');
    }
    final saved = await _catalogStore.add(item);
    _catalog = [..._catalog, saved];
    await _cacheCatalog();
    notifyListeners();
  }

  String? catalogError;
  void _restoreCatalogCache(SharedPreferences prefs) {
    try {
      final raw = prefs.getString('catalogCache');
      if (raw == null) return;
      _catalog = (jsonDecode(raw) as List).map((e) {
        final data = Map<String, dynamic>.from(e as Map);
        return CatalogItem.fromJson(data, id: data['id'] as String? ?? '');
      }).toList();
    } catch (_) {}
  }

  Future<void> _cacheCatalog() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(
        'catalogCache',
        jsonEncode(_catalog
            .map((item) => {...item.toJson(), 'id': item.id})
            .toList()));
  }

  Future<void> refreshCatalog() async {
    try {
      final incoming = await _catalogStore.load();
      _catalog = incoming;
      await _cacheCatalog();
      catalogError = null;
    } catch (_) {
      catalogError =
          'No se pudo actualizar el catálogo. Se conserva la última copia.';
    }
    notifyListeners();
  }

  Future<void> loadCatalogFromFirestore() async {
    await refreshCatalog();
    _catalogTimer?.cancel();
    if (_authenticatedUserId() != null) {
      _catalogTimer = Timer.periodic(
          const Duration(minutes: 2), (_) => unawaited(refreshCatalog()));
    }
  }

  String _profilesKey(String userId) => 'profiles:$userId';
  String _activeProfileKey(String userId) => 'activeProfile:$userId';

  /// Carga los perfiles guardados para [userId] (y cuál queda activo).
  /// Si es la primera vez, crea los 3 perfiles de muestra de siempre
  /// para que la pantalla no empiece vacía.
  Future<void> loadProfiles(String userId) async {
    _profileUserId = userId;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    _loadWatchHistory(prefs);
    _profiles =
        prefs.getStringList(_profilesKey(userId)) ?? ['Ana', 'Luis', 'Kids'];
    _activeProfile = prefs.getString(_activeProfileKey(userId)) ??
        (_profiles.isNotEmpty ? _profiles.first : null);
    notifyListeners();
    await _persistProfiles();
    _startProgressSync();
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
    final day =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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
    if (trimmed.isEmpty) return;
    if (_profiles.contains(trimmed)) {
      // Permite reintentar un guardado que falló tras actualizar la memoria.
      await _persistProfiles();
      return;
    }
    _profiles.add(trimmed);
    notifyListeners();
    await _persistProfiles();
  }

  /// Elimina el perfil [name]. Si era el activo, el primero que quede
  /// pasa a ser el nuevo activo.
  Future<void> removeProfile(String name) async {
    final scope = jsonEncode([_profileUserId, name]);
    final entries = Map<String, WatchProgress>.from(_watchHistory[scope] ?? {});
    for (final entry in entries.entries) {
      await saveWatchProgress(entry.key, Duration.zero,
          Duration(milliseconds: entry.value.durationMs),
          scope: scope);
    }
    _viewedTitles.remove(scope);
    await _persistWatchHistory();
    unawaited(syncWatchProgress());
    _profiles.remove(name);
    if (_activeProfile == name) {
      _activeProfile = _profiles.isNotEmpty ? _profiles.first : null;
    }
    notifyListeners();
    await _persistProfiles();
  }
}

class WatchProgress {
  const WatchProgress(this.positionMs, this.durationMs, [this.updatedAt = 0]);
  final int updatedAt;
  final int positionMs;
  final int durationMs;
  double get fraction => positionMs / durationMs;
}

/// Instancia única compartida por toda la app.
final AppState appState = AppState();
