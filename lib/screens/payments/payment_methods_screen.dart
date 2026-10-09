import 'package:flutter/material.dart';

/// Req. 11: gestión de métodos de pago.
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final methods = const [
      {'nombre': 'Visa •••• 4242', 'detalle': 'Vence 08/28 · Principal'},
      {'nombre': 'Mastercard •••• 1881', 'detalle': 'Vence 03/27'},
      {'nombre': 'Billetera digital', 'detalle': 'Vinculada'},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Métodos de pago')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...methods.map(
            (m) => Card(
              child: ListTile(
                leading: const Icon(Icons.credit_card),
                title: Text(m['nombre']!),
                subtitle: Text(m['detalle']!),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: () {}),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () {}, child: const Text('+ Agregar método')),
        ],
      ),
    );
  }
}
