import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'menu_screen.dart';
import 'content_detail_screen.dart';
import 'payments/subscription_screen.dart';
import 'catalog/notifications_screen.dart';
import 'catalog/downloads_screen.dart';
import 'tokens/tokens_screen.dart';

/// Req. 17, 28, 39: pantalla de inicio con sugerencias, seguir viendo y recomendaciones.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _row(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, __) => GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContentDetailScreen()),
              ),
              child: Container(
                width: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF0F4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuScreen())),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.stars_outlined),
            tooltip: 'Mis tokens',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TokensScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notificaciones',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Descargas',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DownloadsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Mi suscripción',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _row(context, 'Sugerencias'),
          _row(context, 'Seguir viendo'),
          _row(context, 'Para ti'),
        ],
      ),
    );
  }
}
