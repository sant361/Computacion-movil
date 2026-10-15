import 'package:flutter/material.dart';
import 'player_screen.dart';
import 'tokens/access_options_screen.dart';
import '../state/app_state.dart';

/// Req. 19: ficha de un contenido (serie/película) antes de reproducir.
class ContentDetailScreen extends StatelessWidget {
  final String title;
  const ContentDetailScreen({super.key, this.title = 'Título de la serie'});

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
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                      MaterialPageRoute(builder: (_) => PlayerScreen(contentTitle: title)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListenableBuilder(
                  listenable: appState,
                  builder: (context, _) {
                    final inMyList = appState.isInMyList(title);
                    final downloaded = appState.isDownloaded(title);
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: Icon(inMyList ? Icons.favorite : Icons.favorite_border),
                                label: Text(inMyList ? 'En mi lista' : '+ Mi lista'),
                                onPressed: () => appState.toggleMyList(title),
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
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: Icon(downloaded ? Icons.check_circle : Icons.download_outlined),
                            label: Text(downloaded ? 'Descargado' : 'Descargar'),
                            onPressed: downloaded
                                ? null
                                : () {
                                    appState.downloadContent(title);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Descarga completa')),
                                    );
                                  },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.lock_outline, size: 18),
                  label: const Text('Este episodio está restringido'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccessOptionsScreen()),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
