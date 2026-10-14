import 'package:flutter/material.dart';

/// Req. 58: gestión administrativa de planes.
class PlansPanelScreen extends StatelessWidget {
  const PlansPanelScreen({super.key});

  static const plans = [
    {'nombre': 'Básico', 'precio': '\$00.000'},
    {'nombre': 'Estándar', 'precio': '\$00.000'},
    {'nombre': 'Premium', 'precio': '\$00.000'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planes'),
        actions: [
          TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Formulario de nuevo plan (demo)'))), child: const Text('+ Nuevo', style: TextStyle(color: Colors.white))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...plans.map(
            (p) => Card(
              child: ListTile(
                title: Text(p['nombre']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Límites: dispositivos, calidad y descargas'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${p['precio']}/mes'),
                    IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Editar plan (demo)')))),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan eliminado (demo)')))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('Los cambios aplican a nuevas suscripciones', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
