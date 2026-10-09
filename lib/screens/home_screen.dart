import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'menu_screen.dart';

/// Req. 17, 28, 39: pantalla de inicio con sugerencias, seguir viendo y recomendaciones.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _row(String title) {
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
            itemBuilder: (_, __) => Container(
              width: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF0F4),
                borderRadius: BorderRadius.circular(8),
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
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _row('Sugerencias'),
          _row('Seguir viendo'),
          _row('Para ti'),
        ],
      ),
    );
  }
}
