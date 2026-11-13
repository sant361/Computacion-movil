import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Guarda el documento `users/{uid}` de cada cuenta en Firestore.
///
/// Authentication solo guarda correo y contraseña; este documento es el
/// registro de la persona en la base de datos (nombre, correo, fechas).
/// Si falla (sin internet, reglas), nunca debe impedir registrarse o entrar.
class UserStore {
  const UserStore._();

  static DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  /// Se llama justo después de crear la cuenta.
  static Future<void> saveOnRegister(User user, String name) async {
    try {
      await _doc(user.uid).set({
        'name': name,
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  /// Se llama al iniciar sesión. También crea el documento de las cuentas
  /// que se registraron antes de que existiera.
  static Future<void> touchOnLogin(User user) async {
    try {
      await _doc(user.uid).set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }
}
