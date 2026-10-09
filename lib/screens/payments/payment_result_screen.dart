import 'package:flutter/material.dart';
import '../../widgets/primary_button.dart';

/// Req. 12: resultado del pago (aprobado / rechazado).
class PaymentResultScreen extends StatelessWidget {
  final bool success;
  const PaymentResultScreen({super.key, required this.success});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Icon(
                success ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 64,
                color: success ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                success ? 'Pago aprobado' : 'Pago rechazado',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                success
                    ? 'Tu plan Estándar ya está activo.'
                    : 'No pudimos procesar tu pago. Revisa tus datos o prueba otro método.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const Spacer(),
              PrimaryButton(
                label: success ? 'IR AL INICIO' : 'REINTENTAR',
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
