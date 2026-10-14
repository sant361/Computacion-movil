import 'package:flutter/material.dart';
import '../../widgets/primary_button.dart';

/// Req. 5: recuperación de contraseña.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // TODO: enviar la solicitud de recuperación al backend.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enlace enviado a ${_emailController.text}')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailPattern.hasMatch(v.trim())) return 'Correo no válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: 'ENVIAR ENLACE', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
