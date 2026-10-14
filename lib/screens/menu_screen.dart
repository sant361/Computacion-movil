import 'package:flutter/material.dart';
import 'catalog/profiles_screen.dart';
import 'catalog/parental_control_screen.dart';
import 'admin/admin_dashboard_screen.dart';

/// Req. 18, 38: categorías y tipos de contenido.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  static const categorias = ['Comedia', 'Suspenso', 'Acción', 'Infantil', 'Romance'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menú')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...categorias.map(
            (c) => Card(
              child: ListTile(
                title: Text(c),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: navegar al listado filtrado por categoría.
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: const [
              Chip(label: Text('Películas')),
              Chip(label: Text('Series')),
              Chip(label: Text('Documentales')),
            ],
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Perfiles'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilesScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Control parental'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentalControlScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: const Text('Panel de administrador'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
          ),
        ],
      ),
    );
  }
}
