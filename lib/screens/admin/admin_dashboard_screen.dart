import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import 'content_panel_screen.dart';
import 'users_roles_screen.dart';
import 'plans_panel_screen.dart';
import 'promotions_panel_screen.dart';
import 'analytics_panel_screen.dart';
import 'region_security_screen.dart';

/// Punto de entrada a los paneles de administrador (req. 52-66).
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!appState.isAdmin) {
      return Scaffold(
          appBar: AppBar(title: const Text('Panel de administrador')),
          body: const Center(
              child:
                  Text('Esta sección está disponible para administradores.')));
    }
    final items = [
      ('Contenido', Icons.movie_outlined, const ContentPanelScreen()),
      ('Usuarios y roles', Icons.group_outlined, const UsersRolesScreen()),
      ('Planes', Icons.card_membership_outlined, const PlansPanelScreen()),
      (
        'Promociones',
        Icons.local_offer_outlined,
        const PromotionsPanelScreen()
      ),
      ('Analítica', Icons.bar_chart, const AnalyticsPanelScreen()),
      (
        'Región y seguridad',
        Icons.security_outlined,
        const RegionSecurityScreen()
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Panel de administrador')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: items
            .map(
              (item) => Card(
                child: ListTile(
                  leading: Icon(item.$2),
                  title: Text(item.$1),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => item.$3),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
