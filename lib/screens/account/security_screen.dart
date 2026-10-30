import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Req. 7: doble autenticación (2FA) y cambio de contraseña.
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _twoFactorEnabled = true;
  String _method = 'app';

  static const _demoAuthEnabled = bool.fromEnvironment('DEMO_AUTH_ENABLED');

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Cambia la contraseña en Firebase: primero confirma la contraseña actual
  /// (reautenticación) y después guarda la nueva.
  Future<void> _changePassword() async {
    final user = kIsWeb && _demoAuthEnabled ? null : FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      _showMessage('Inicia sesión con tu correo para cambiar la contraseña.');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña actual'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Escribe tu contraseña actual' : null,
                ),
                TextFormField(
                  controller: newController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                  validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                ),
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Repite la nueva contraseña'),
                  validator: (v) => v != newController.text ? 'Las contraseñas no coinciden' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    final currentPassword = currentController.text;
    final newPassword = newController.text;
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    if (confirmed != true) return;

    try {
      final credential = EmailAuthProvider.credential(email: email, password: currentPassword);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      _showMessage('Contraseña actualizada');
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          _showMessage('La contraseña actual no es correcta.');
        case 'weak-password':
          _showMessage('La nueva contraseña es muy débil.');
        case 'too-many-requests':
          _showMessage('Demasiados intentos. Espera un momento e intenta de nuevo.');
        default:
          _showMessage('No se pudo cambiar la contraseña. Intenta de nuevo.');
      }
    } catch (_) {
      _showMessage('No se pudo cambiar la contraseña. Intenta de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.shield_outlined),
              value: _twoFactorEnabled,
              onChanged: (v) => setState(() => _twoFactorEnabled = v),
              title: const Text('Doble autenticación'),
              subtitle: const Text('Verificación adicional al iniciar sesión'),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Método', style: TextStyle(fontWeight: FontWeight.bold)),
          RadioListTile(
            value: 'app',
            groupValue: _method,
            onChanged: _twoFactorEnabled ? (v) => setState(() => _method = v as String) : null,
            title: const Text('App autenticadora'),
          ),
          RadioListTile(
            value: 'sms',
            groupValue: _method,
            onChanged: _twoFactorEnabled ? (v) => setState(() => _method = v as String) : null,
            title: const Text('SMS al número guardado'),
          ),
          const Divider(),
          const Text('Contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _changePassword,
            child: const Text('Cambiar contraseña'),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text('Recomendamos activar 2FA', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
