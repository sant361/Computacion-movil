import 'package:flutter/material.dart';

/// Req. 63, 64: métricas de uso, ingresos y contenido popular.
class AnalyticsPanelScreen extends StatelessWidget {
  const AnalyticsPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Métricas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _metricRow('Usuarios activos', '24.500'),
          _metricRow('Reproducciones', '118.900'),
          _metricRow('Ingresos del mes', '\$00.000.000'),
          const SizedBox(height: 16),
          Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart, size: 40, color: Colors.grey),
                SizedBox(height: 4),
                Text('Reproducciones por semana', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Contenido popular', style: TextStyle(fontWeight: FontWeight.bold)),
          const ListTile(title: Text('Serie A'), trailing: Text('2400 vistas'), contentPadding: EdgeInsets.zero),
          const ListTile(title: Text('Película B'), trailing: Text('1200 vistas'), contentPadding: EdgeInsets.zero),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abriendo registro de errores (demo)'))), child: const Text('Ver errores del sistema')),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
