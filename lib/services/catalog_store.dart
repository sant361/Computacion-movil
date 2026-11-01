import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/catalog_item.dart';

abstract class CatalogStore {
  Future<List<CatalogItem>> load();
  Future<CatalogItem> add(CatalogItem item);
  Future<void> update(CatalogItem item);
  Future<void> delete(CatalogItem item);
  Future<List<Map<String, dynamic>>> statistics();
}

class FirestoreCatalogStore implements CatalogStore {
  FirestoreCatalogStore(
      {FirebaseFirestore? firestore, String? Function()? authenticatedUserId})
      : _firestore = firestore,
        _authenticatedUserId = authenticatedUserId ?? _currentUser;

  static String? _currentUser() => FirebaseAuth.instance.currentUser?.uid;
  final FirebaseFirestore? _firestore;
  final String? Function() _authenticatedUserId;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Future<void> _requireAdmin() async {
    final uid = _authenticatedUserId();
    if (uid == null) {
      throw StateError('Inicia sesión con una cuenta administradora.');
    }
    final admin = await _db
        .collection('admins')
        .doc(uid)
        .get()
        .timeout(const Duration(seconds: 10));
    if (!admin.exists) {
      throw StateError('Esta cuenta no tiene permisos de administrador.');
    }
  }

  @override
  Future<List<CatalogItem>> load() async {
    final snapshot = await _db
        .collection('catalog')
        .get()
        .timeout(const Duration(seconds: 10));
    return snapshot.docs
        .map((doc) => CatalogItem.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  @override
  Future<CatalogItem> add(CatalogItem item) async {
    await _requireAdmin();
    final error = item.validationError;
    if (error != null) throw ArgumentError(error);
    final ref = _db.collection('catalog').doc();
    await ref.set(item.toJson()).timeout(const Duration(seconds: 10));
    return item.copyWith(id: ref.id);
  }

  @override
  Future<void> update(CatalogItem item) async {
    await _requireAdmin();
    final error = item.validationError;
    if (error != null) throw ArgumentError(error);
    if (item.id.isEmpty) {
      throw StateError('El título todavía no está guardado en Firebase.');
    }
    await _db
        .collection('catalog')
        .doc(item.id)
        .update(item.toJson())
        .timeout(const Duration(seconds: 10));
  }

  @override
  Future<void> delete(CatalogItem item) async {
    await _requireAdmin();
    if (item.id.isEmpty) {
      throw StateError('El título todavía no está guardado en Firebase.');
    }
    await _db
        .collection('catalog')
        .doc(item.id)
        .delete()
        .timeout(const Duration(seconds: 10));
  }

  @override
  Future<List<Map<String, dynamic>>> statistics() async {
    await _requireAdmin();
    final snapshot = await _db
        .collectionGroup('playEvents')
        .get()
        .timeout(const Duration(seconds: 10));
    final grouped = <String, Map<String, dynamic>>{};
    for (final doc in snapshot.docs) {
      final title = doc.data()['title'] as String? ?? '';
      final genre = doc.data()['genre'] as String? ?? '';
      if (title.isEmpty) continue;
      final row = grouped.putIfAbsent(
          title,
          () => {
                'title': title,
                'genre': genre,
                'plays': 0,
              });
      row['plays'] = (row['plays'] as int) + 1;
    }
    final rows = grouped.values.toList();
    rows.sort((a, b) => (b['plays'] as int).compareTo(a['plays'] as int));
    return rows;
  }
}
