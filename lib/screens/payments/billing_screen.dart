import 'package:flutter/material.dart';

/// Req. 13: historial de comprobantes de facturación.
class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Facturación')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, i) => Card(
          child: ListTile(
            title: Text('Factura 0001${23 - i}'),
            subtitle: const Text('00/00/0000 · Pagada'),
            trailing: IconButton(icon: const Icon(Icons.download), onPressed: () {}),
          ),
        ),
      ),
    );
  }
}
