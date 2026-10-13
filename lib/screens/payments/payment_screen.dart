import 'package:flutter/material.dart';
import '../../widgets/primary_button.dart';
import 'payment_result_screen.dart';
import 'payment_methods_screen.dart';

/// Req. 11, 12, 62: método de pago, código promocional y procesamiento.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _autoRenew = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Plan Estándar', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Renovación mensual'),
              trailing: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cambiar'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Método de pago', style: TextStyle(fontWeight: FontWeight.bold)),
          ListTile(
            leading: const Icon(Icons.radio_button_checked),
            title: const Text('•••• 4242'),
            onTap: () {},
          ),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen())),
            child: const Text('+ Agregar método'),
          ),
          Row(
            children: [
              Expanded(child: TextField(decoration: InputDecoration(hintText: 'Código promocional'))),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código aplicado (demo)')),
                ),
                child: const Text('Aplicar'),
              ),
            ],
          ),
          SwitchListTile(
            value: _autoRenew,
            onChanged: (v) => setState(() => _autoRenew = v),
            title: const Text('Renovación automática'),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          const ListTile(
            title: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text('\$00.000', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'PAGAR',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentResultScreen(success: true)),
            ),
          ),
        ],
      ),
    );
  }
}
