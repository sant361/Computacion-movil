import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../widgets/primary_button.dart';
import '../home_screen.dart';

/// Req. 6: verificación de correo.
///
/// Firebase no envía un código de 6 dígitos: envía un enlace al correo. La
/// persona abre el enlace (en cualquier dispositivo), vuelve a la app y toca
/// "YA VERIFIQUÉ MI CORREO"; aquí se consulta a Firebase si ya quedó verificado.
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const _demoAuthEnabled = bool.fromEnvironment('DEMO_AUTH_ENABLED');

  bool _checking = false;
  bool _resending = false;

  User? get _user => kIsWeb && _demoAuthEnabled ? null : FirebaseAuth.instance.currentUser;

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _checkVerified() async {
    final user = _user;
    if (user == null) {
      _showMessage('No hay una sesión activa. Vuelve a iniciar sesión.');
      return;
    }
    setState(() => _checking = true);
    try {
      await user.reload();
      final fresh = FirebaseAuth.instance.currentUser;
      if (fresh == null || !fresh.emailVerified) {
        _showMessage('Todavía no vemos tu correo verificado. Abre el enlace del correo y vuelve a intentar.');
        return;
      }
      await appState.login();
      await appState.loadCatalogFromFirestore();
      await appState.loadProfiles(fresh.uid);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException {
      _showMessage('No se pudo comprobar la verificación. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    final user = _user;
    if (user == null) {
      _showMessage('No hay una sesión activa. Vuelve a iniciar sesión.');
      return;
    }
    setState(() => _resending = true);
    try {
      await user.sendEmailVerification();
      _showMessage('Te enviamos un nuevo enlace de verificación');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        _showMessage('Espera un momento antes de pedir otro correo.');
      } else {
        _showMessage('No se pudo reenviar el correo. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Icon(Icons.mark_email_unread_outlined, size: 48),
              const SizedBox(height: 16),
              const Text('Verifica tu correo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Enviamos un enlace de verificación a ${widget.email}', textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'Abre el correo, toca el enlace y vuelve aquí. Si no lo ves, revisa la carpeta de spam.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _checking ? 'COMPROBANDO...' : 'YA VERIFIQUÉ MI CORREO',
                onPressed: _checking ? null : _checkVerified,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _resending ? null : _resend,
                child: Text(_resending ? 'Enviando...' : '¿No llegó el correo? Reenviar enlace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
