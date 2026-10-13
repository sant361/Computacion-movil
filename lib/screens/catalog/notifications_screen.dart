import 'package:flutter/material.dart';

/// Req. 43, 44: centro de notificaciones y preferencias.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Map<String, bool> _preferences = {
    'Estrenos': true,
    'Cuenta y pagos': true,
    'Novedades': true,
  };

  final List<Map<String, String>> _notifications = const [
    {'titulo': 'Nuevo capítulo disponible', 'detalle': 'Serie · hace 2 h'},
    {'titulo': 'Tu pago fue aprobado', 'detalle': 'Plan Estándar · hoy'},
    {'titulo': 'Estreno esta semana', 'detalle': 'Película · hace 1 día'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._notifications.map(
            (n) => ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(n['titulo']!),
              subtitle: Text(n['detalle']!),
            ),
          ),
          const Divider(height: 32),
          const Text('Preferencias', style: TextStyle(fontWeight: FontWeight.bold)),
          ..._preferences.keys.map(
            (k) => SwitchListTile(
              title: Text(k),
              value: _preferences[k]!,
              onChanged: (v) => setState(() => _preferences[k] = v),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
