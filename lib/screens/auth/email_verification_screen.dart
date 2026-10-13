import 'package:flutter/material.dart';
import '../../widgets/primary_button.dart';
import '../home_screen.dart';

/// Req. 6: verificación de correo con código de 6 dígitos.
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());

  String get _code => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
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
              Text('Enviamos un código a ${widget.email}', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (i) => SizedBox(
                    width: 42,
                    child: TextField(
                      controller: _controllers[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      decoration: const InputDecoration(counterText: ''),
                      onChanged: (v) {
                        if (v.isNotEmpty && i < 5) {
                          FocusScope.of(context).nextFocus();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('El código expira en 04:59', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'VERIFICAR',
                onPressed: () {
                  // TODO: validar _code contra el backend.
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // TODO: reenviar código.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código reenviado')),
                  );
                },
                child: const Text('¿No llegó el código? Reenviar código'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
