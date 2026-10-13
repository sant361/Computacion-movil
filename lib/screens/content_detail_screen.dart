import 'package:flutter/material.dart';
import 'player_screen.dart';

/// Req. 19: ficha de un contenido (serie/película) antes de reproducir.
class ContentDetailScreen extends StatefulWidget {
  final String title;
  const ContentDetailScreen({super.key, this.title = 'Título de la serie'});

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  bool _inMyList = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFFEEF0F4),
                child: const Center(child: Icon(Icons.play_circle_outline, size: 56)),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('2026 · 3 temporadas · +14', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: const [
                    Chip(label: Text('Drama')),
                    Chip(label: Text('Suspenso')),
                    Chip(label: Text('Acción')),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sinopsis: descripción del contenido, lista para reemplazar con los datos reales '
                  'del catálogo (reparto, director, temporadas, episodios).',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('REPRODUCIR'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlayerScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(_inMyList ? Icons.favorite : Icons.favorite_border),
                        label: Text(_inMyList ? 'En mi lista' : '+ Mi lista'),
                        onPressed: () => setState(() => _inMyList = !_inMyList),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share),
                        label: const Text('Compartir'),
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enlace copiado para compartir')),
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
