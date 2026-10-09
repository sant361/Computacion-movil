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
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen())),
            ),
          ],
        ),
      ),
    );
  }
}
