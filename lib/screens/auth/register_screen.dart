import 'package:flutter/material.dart';
import '../../widgets/primary_button.dart';

/// Req. 1: registro de usuario.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            TextField(decoration: InputDecoration(labelText: 'Nombre completo')),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Correo electrónico')),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Contraseña'), obscureText: true),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Confirmar contraseña'), obscureText: true),
            SizedBox(height: 16),
            PrimaryButton(label: 'REGISTRARME'),
          ],
        ),
      ),
    );
  }
}
