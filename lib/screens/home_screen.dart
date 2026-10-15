import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'menu_screen.dart';
import 'content_detail_screen.dart';
import 'payments/subscription_screen.dart';
import 'catalog/notifications_screen.dart';
import 'catalog/downloads_screen.dart';
import 'tokens/tokens_screen.dart';
import '../data/catalog_item.dart';

/// Req. 17, 28, 39: pantalla de inicio con sugerencias, seguir viendo y recomendaciones.
///
/// Las tres filas usan franjas distintas del mismo catálogo de muestra
/// (lib/data/catalog_item.dart) solo para tener algo real con qué navegar;
/// en una versión con backend cada fila vendría de un endpoint distinto.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final List<CatalogItem> _sugerencias = sampleCatalog.take(5).toList();
  static final List<CatalogItem> _seguirViendo = sampleCatalog.skip(5).take(3).toList();
  static final List<CatalogItem> _paraTi = sampleCatalog.reversed.take(5).toList();

  Widget _row(BuildContext context, String title, List<CatalogItem> items, {bool showProgress = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: showProgress ? 100 : 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final item = items[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ContentDetailScreen(title: item.title)),
                ),
                child: SizedBox(
                  width: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF0F4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      if (showProgress) ...[
                        const SizedBox(height: 4),
                        LinearProgressIndicator(value: 0.3 + i * 0.2, minHeight: 3),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            },
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
          _row(context, 'Sugerencias', _sugerencias),
          _row(context, 'Seguir viendo', _seguirViendo, showProgress: true),
          _row(context, 'Para ti', _paraTi),
        ],
      ),
    );
  }
}
