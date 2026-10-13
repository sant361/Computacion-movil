import 'package:flutter/material.dart';
import '../../widgets/primary_button.dart';
import 'email_verification_screen.dart';

/// Req. 1: registro de usuario.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Nombre completo')),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correo electrónico'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Contraseña'), obscureText: true),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Confirmar contraseña'), obscureText: true),
            CheckboxListTile(
              value: _acceptedTerms,
              onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
              title: const Text('Autorizo el tratamiento de mis datos personales'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'REGISTRARME',
              onPressed: _acceptedTerms
                  ? () {
                      // TODO: enviar el registro al backend.
                      final email = _emailController.text.isEmpty ? 'correo@ejemplo.com' : _emailController.text;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EmailVerificationScreen(email: email)),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
