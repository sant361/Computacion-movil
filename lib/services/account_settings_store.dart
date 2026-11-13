import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Datos de la cuenta que deben seguirla a cualquier dispositivo:
/// saldo de tokens y control parental (sin el PIN, que se queda en el equipo).
///
/// Se guardan en `users/{uid}/settings/account`. Si Firebase no está
/// disponible o falla la red, las funciones no lanzan errores: la app sigue
/// usando la copia local.
class AccountSettings {
  final int tokenBalance;
  final String parentalMaxRating;
  final bool parentalRestrictByProfile;
  final bool parentalBlockPurchases;

  const AccountSettings({
    required this.tokenBalance,
    required this.parentalMaxRating,
    required this.parentalRestrictByProfile,
    required this.parentalBlockPurchases,
  });
}

class AccountSettingsStore {
  const AccountSettingsStore();

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('account');

  /// Devuelve los datos guardados, o `null` si no hay, no hay conexión o
  /// Firebase no está iniciado.
  Future<AccountSettings?> read(String uid) async {
    if (Firebase.apps.isEmpty) return null;
    try {
      final snap = await _doc(uid).get().timeout(const Duration(seconds: 8));
      final data = snap.data();
      if (data == null) return null;
      final tokens = data['tokenBalance'];
      final rating = data['parentalMaxRating'];
      if (tokens is! int || tokens < 0 || rating is! String) return null;
      return AccountSettings(
        tokenBalance: tokens,
        parentalMaxRating: rating,
        parentalRestrictByProfile:
            data['parentalRestrictByProfile'] as bool? ?? true,
        parentalBlockPurchases: data['parentalBlockPurchases'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String uid, AccountSettings settings) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await _doc(uid).set({
        'tokenBalance': settings.tokenBalance,
        'parentalMaxRating': settings.parentalMaxRating,
        'parentalRestrictByProfile': settings.parentalRestrictByProfile,
        'parentalBlockPurchases': settings.parentalBlockPurchases,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }
}
