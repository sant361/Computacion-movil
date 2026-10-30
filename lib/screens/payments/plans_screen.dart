import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../widgets/primary_button.dart';
import 'payment_screen.dart';

/// Req. 9, 10: visualización y selección de planes.
class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  int _selected = 1;
  final planes = const [
    {'nombre': 'Básico', 'precio': '\$00.000/mes'},
    {'nombre': 'Estándar', 'precio': '\$00.000/mes'},
    {'nombre': 'Premium', 'precio': '\$00.000/mes'},
  ];

  /// Guarda en Firestore el plan elegido (subscriptions/{uid}). Si falla
  /// (sin internet, sin sesión), no bloquea el flujo de pago.
  Future<void> _saveSubscription() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance.collection('subscriptions').doc(user.uid).set({
        'plan': planes[_selected]['nombre'],
        'autoRenew': true,
        'cancelAtPeriodEnd': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Se ignora a propósito: el pago simulado debe poder continuar.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: planes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: _selected == i ? Colors.black : Colors.grey.shade300),
                  ),
                  child: RadioListTile(
                    value: i,
                    groupValue: _selected,
                    onChanged: (v) => setState(() => _selected = v as int),
                    title: Text(planes[i]['nombre']!),
                    secondary: Text(planes[i]['precio']!),
                  ),
                ),
              ),
            ),
            const Text(
              'Renovación automática. Cancela cuando quieras.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'SUSCRIBIRME',
              onPressed: () async {
                await _saveSubscription();
                if (!context.mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
