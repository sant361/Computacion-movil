import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../widgets/catalog_artwork.dart';
import '../content_detail_screen.dart';

class MyListScreen extends StatelessWidget {
  const MyListScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final items = appState.catalog
              .where((item) => appState.myListTitles.contains(item.title))
              .toList();
          return Scaffold(
            appBar: AppBar(title: const Text('Mi lista')),
            body: items.isEmpty
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'Guarda títulos desde su ficha para encontrarlos aquí.',
                            textAlign: TextAlign.center)))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: SizedBox(
                            width: 56,
                            height: 72,
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: CatalogArtwork(url: item.posterUrl))),
                        title: Text(item.title),
                        subtitle: Text('${item.genre} · ${item.year}'),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ContentDetailScreen(title: item.title))),
                        trailing: IconButton(
                            tooltip: 'Quitar ${item.title} de Mi lista',
                            icon: const Icon(Icons.favorite),
                            onPressed: () => appState.toggleMyList(item.title)),
                      );
                    }),
          );
        },
      );
}
