import 'package:flutter/material.dart';
import 'add_payment_method_screen.dart';

/// Req. 11: gestión de métodos de pago.
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, String>> _methods = [
    {'nombre': 'Visa •••• 4242', 'detalle': 'Vence 08/28 · Principal'},
    {'nombre': 'Mastercard •••• 1881', 'detalle': 'Vence 03/27'},
    {'nombre': 'Billetera digital', 'detalle': 'Vinculada'},
  ];

  Future<void> _confirmDelete(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar este método?'),
        content: Text('Se eliminará "${_methods[index]['nombre']}" de tu cuenta.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _methods.removeAt(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Métodos de pago')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._methods.asMap().entries.map(
                (entry) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.credit_card),
                    title: Text(entry.value['nombre']!),
                    subtitle: Text(entry.value['detalle']!),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () {
                            // TODO: abrir formulario de edición con los datos actuales.
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => _confirmDelete(entry.key),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddPaymentMethodScreen()),
            ),
            child: const Text('+ Agregar método'),
          ),
        ],
      ),
    );
  }
}
