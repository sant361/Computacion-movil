import 'package:flutter/material.dart';

/// Req. 52, 53: administración de contenido, temporadas y episodios.
class ContentPanelScreen extends StatelessWidget {
  const ContentPanelScreen({super.key});

  static const items = [
    {'nombre': 'Serie A', 'estado': 'Publicado', 'color': Colors.green},
    {'nombre': 'Película B', 'estado': 'Revisión', 'color': Colors.orange},
    {'nombre': 'Serie C', 'estado': 'Borrador', 'color': Colors.grey},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contenido'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: abrir formulario de carga de nuevo contenido.
            },
            child: const Text('+ Nuevo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...items.map(
            (c) => Card(
              child: ListTile(
                leading: Container(width: 40, height: 40, color: const Color(0xFFEEF0F4)),
                title: Text(c['nombre'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Chip(
                  label: Text(c['estado'] as String, style: TextStyle(color: c['color'] as Color)),
                  visualDensity: VisualDensity.compact,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: () {}),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 32),
          const Text('Temporadas y episodios', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () {}, child: const Text('Panel de temporadas')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () {}, child: const Text('Panel de episodios')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () {}, child: const Text('Formulario de carga multimedia')),
          const SizedBox(height: 16),
          const Center(
            child: Text('Estados: borrador · revisión · programado', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
