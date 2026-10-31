import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Un registro por título y perfil. positionMs == 0 marca un reinicio o final.
class SyncedProgress {
  const SyncedProgress(
      {required this.profile,
      required this.title,
      required this.positionMs,
      required this.durationMs,
      required this.updatedAt});
  final String profile;
  final String title;
  final int positionMs;
  final int durationMs;
  final int updatedAt;

  Map<String, dynamic> toJson() => {
        'profile': profile,
        'title': title,
        'positionMs': positionMs,
        'durationMs': durationMs,
        'updatedAt': updatedAt,
      };

  static SyncedProgress? fromJson(Map<String, dynamic> data) {
    final profile = data['profile'];
    final title = data['title'];
    final position = data['positionMs'];
    final duration = data['durationMs'];
    final updated = data['updatedAt'];
    if (profile is! String ||
        title is! String ||
        position is! int ||
        duration is! int ||
        updated is! int ||
        position < 0 ||
        duration <= 0 ||
        position >= duration ||
        updated < 0) {
      return null;
    }
    return SyncedProgress(
        profile: profile,
        title: title,
        positionMs: position,
        durationMs: duration,
        updatedAt: updated);
  }
}

abstract class ProgressStore {
  Stream<List<SyncedProgress>> watch(String userId);
  Future<void> write(String userId, SyncedProgress progress);
}

class FirestoreProgressStore implements ProgressStore {
  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('watchProgress');

  @override
  Stream<List<SyncedProgress>> watch(String userId) => _collection(userId)
      .snapshots(includeMetadataChanges: true)
      .where((snapshot) => !snapshot.metadata.isFromCache)
      .map((snapshot) => snapshot.docs
          .map((doc) => SyncedProgress.fromJson(doc.data()))
          .whereType<SyncedProgress>()
          .toList());

  @override
  Future<void> write(String userId, SyncedProgress progress) async {
    final id = base64Url
        .encode(utf8.encode(jsonEncode([progress.profile, progress.title])));
    final ref = _collection(userId).doc(id);
    // La transacción evita que un dispositivo atrasado sobrescriba al más reciente.
    // Si no hay red, AppState conserva el pendiente en SharedPreferences.
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final current = snapshot.data()?['updatedAt'];
      if (current is int && current >= progress.updatedAt) return;
      transaction.set(ref, progress.toJson());
    }).timeout(const Duration(seconds: 10));
  }
}
