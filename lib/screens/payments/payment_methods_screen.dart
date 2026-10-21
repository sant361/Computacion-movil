import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import 'add_payment_method_screen.dart';

/// Req. 11: gestión de métodos de pago, conectada a AppState (persistida
/// por cuenta, sin guardar nunca el número completo ni el CVV).
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, Map<String, String> method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar este método?'),
        content: Text('Se eliminará "${method['nombre']}" de tu cuenta.'),
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
      await appState.removePaymentMethod(method['id']!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Métodos de pago')),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final methods = appState.paymentMethods;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (methods.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No tienes métodos de pago guardados',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...methods.map(
                  (method) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.credit_card),
                      title: Text(method['nombre']!),
                      subtitle: Text(method['detalle']!),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (method['principal'] == 'true')
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Text('Principal', style: TextStyle(fontSize: 11, color: Colors.green)),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => _confirmDelete(context, method),
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
          );
        },
      ),
    );
  }
}
