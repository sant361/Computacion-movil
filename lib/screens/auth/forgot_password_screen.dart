import 'package:flutter/material.dart';
import '../../widgets/primary_button.dart';

/// Req. 5: recuperación de contraseña.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar cuenta')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Correo electrónico')),
            SizedBox(height: 16),
            PrimaryButton(label: 'ENVIAR ENLACE'),
          ],
        ),
      ),
    );
  }
}
