import 'package:flutter/material.dart';

/// Req. 8: dispositivos con sesión activa.
class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final List<Map<String, Object>> _devices = [
    {'nombre': 'iPhone 14', 'detalle': 'Bogotá · ahora', 'actual': true, 'icono': Icons.phone_iphone},
    {'nombre': 'Chrome · Windows', 'detalle': 'Medellín · hace 2 h', 'actual': false, 'icono': Icons.laptop_mac},
    {'nombre': 'Smart TV Samsung', 'detalle': 'Cali · hace 1 día', 'actual': false, 'icono': Icons.tv},
  ];

  void _closeSession(int index) {
    setState(() => _devices.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión cerrada en ese dispositivo')),
    );
  }

  Future<void> _closeAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cerrar todas las sesiones?'),
        content: const Text('Tendrás que volver a iniciar sesión en todos tus dispositivos, incluido este.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar todas', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _devices.removeWhere((d) => d['actual'] != true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispositivos')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _devices.length,
              itemBuilder: (_, i) {
                final d = _devices[i];
                return Card(
                  child: ListTile(
                    leading: Icon(d['icono'] as IconData),
                    title: Text(d['nombre'] as String),
                    subtitle: Text(d['detalle'] as String),
                    trailing: d['actual'] == true
                        ? const Chip(label: Text('Esta sesión'))
                        : TextButton(
                            onPressed: () => _closeSession(i),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Cerrar sesión'),
                          ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _closeAll,
                child: const Text('CERRAR TODAS LAS SESIONES'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
