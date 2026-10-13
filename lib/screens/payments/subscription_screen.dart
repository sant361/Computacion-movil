import 'package:flutter/material.dart';
import 'billing_screen.dart';
import 'payment_methods_screen.dart';
import 'plans_screen.dart';

/// Req. 14, 15, 16: estado de la suscripción, cambio y cancelación de plan.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _autoRenew = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi suscripción')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Estándar', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Renueva el 00/00/0000'),
              trailing: const Text('\$00.000/mes'),
            ),
          ),
          SwitchListTile(
            value: _autoRenew,
            onChanged: (v) => setState(() => _autoRenew = v),
            title: const Text('Renovación automática'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlansScreen()),
            ),
            child: const Text('Cambiar plan'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancelar plan'),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Métodos de pago'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen())),
          ),
          ListTile(
            title: const Text('Facturación'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillingScreen())),
          ),
        ],
      ),
    );
  }
}
