import 'package:flutter/material.dart';
import '../../widgets/primary_button.dart';

/// Req. 11: formulario para agregar un nuevo método de pago.
class AddPaymentMethodScreen extends StatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  bool _saveAsDefault = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar método')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.credit_card),
                labelText: 'Número de tarjeta',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(child: TextField(decoration: InputDecoration(labelText: 'MM/AA'))),
                SizedBox(width: 12),
                Expanded(child: TextField(decoration: InputDecoration(labelText: 'CVV'))),
              ],
            ),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Nombre del titular')),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _saveAsDefault,
              onChanged: (v) => setState(() => _saveAsDefault = v ?? true),
              title: const Text('Guardar como principal'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tus datos se guardan cifrados',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'GUARDAR MÉTODO',
              onPressed: () {
                // TODO: validar y enviar los datos de la tarjeta al backend de pagos.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Método de pago guardado')),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
