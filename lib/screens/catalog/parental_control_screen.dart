import 'package:flutter/material.dart';

/// Req. 41: control parental y clasificación máxima de contenido.
class ParentalControlScreen extends StatefulWidget {
  const ParentalControlScreen({super.key});

  @override
  State<ParentalControlScreen> createState() => _ParentalControlScreenState();
}

class _ParentalControlScreenState extends State<ParentalControlScreen> {
  String _maxRating = '+14';
  bool _restrictByProfile = true;
  bool _blockPurchases = false;
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control parental')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Clasificación máxima', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['TP', '+14', '+18'].map((r) {
              return ChoiceChip(
                label: Text(r),
                selected: _maxRating == r,
                onSelected: (_) => setState(() => _maxRating = r),
              );
            }).toList(),
          ),
          const Divider(height: 32),
          const Text('PIN de control parental', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(hintText: '••••'),
          ),
          const Divider(),
          SwitchListTile(
            value: _restrictByProfile,
            onChanged: (v) => setState(() => _restrictByProfile = v),
            title: const Text('Restringir por perfil'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _blockPurchases,
            onChanged: (v) => setState(() => _blockPurchases = v),
            title: const Text('Bloquear compras'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: guardar configuración en el backend.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Control parental actualizado')),
                );
              },
              child: const Text('GUARDAR CAMBIOS'),
            ),
          ),
        ],
      ),
    );
  }
}
