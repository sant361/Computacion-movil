import 'package:flutter/material.dart';

/// Req. 59, 62: gestión de códigos promocionales.
class PromotionsPanelScreen extends StatefulWidget {
  const PromotionsPanelScreen({super.key});

  @override
  State<PromotionsPanelScreen> createState() => _PromotionsPanelScreenState();
}

class _PromotionsPanelScreenState extends State<PromotionsPanelScreen> {
  final List<Map<String, Object>> _promos = [
    {'codigo': 'BIENVENIDA20', 'detalle': '20% · 1 mes', 'activo': true},
    {'codigo': 'VERANO2026', 'detalle': '10% · campaña', 'activo': true},
    {'codigo': 'EXPIRADA10', 'detalle': '10% · vencido', 'activo': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promociones'),
        actions: [
          TextButton(onPressed: () {}, child: const Text('+ Nuevo', style: TextStyle(color: Colors.white))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._promos.asMap().entries.map(
                (e) => Card(
                  child: SwitchListTile(
                    title: Text(e.value['codigo'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(e.value['detalle'] as String),
                    value: e.value['activo'] as bool,
                    onChanged: (v) => setState(() => _promos[e.key]['activo'] = v),
                  ),
                ),
              ),
          const Divider(height: 32),
          OutlinedButton(onPressed: () {}, child: const Text('Configurar código nuevo')),
          const SizedBox(height: 16),
          const Center(
            child: Text('Los códigos vencidos no se pueden aplicar', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
