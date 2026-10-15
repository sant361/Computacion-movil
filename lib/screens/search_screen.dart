import 'package:flutter/material.dart';
import 'content_detail_screen.dart';
import '../data/catalog_item.dart';

/// Req. 36, 37: búsqueda y filtros, con filtrado real sobre un catálogo de muestra.
class SearchScreen extends StatefulWidget {
  /// Si se pasa, el filtro de género inicia ya seleccionado (por ejemplo al
  /// entrar aquí desde una categoría del Menú).
  final String? initialGenre;

  const SearchScreen({super.key, this.initialGenre});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryController = TextEditingController();
  final Set<String> _selectedGenres = {};

  static const genres = ['Comedia', 'Suspenso', 'Acción', 'Infantil', 'Romance'];

  @override
  void initState() {
    super.initState();
    if (widget.initialGenre != null) _selectedGenres.add(widget.initialGenre!);
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  List<CatalogItem> get _filtered {
    final query = _queryController.text.trim().toLowerCase();
    return sampleCatalog.where((item) {
      final matchesQuery = query.isEmpty || item.title.toLowerCase().contains(query);
      final matchesGenre = _selectedGenres.isEmpty || _selectedGenres.contains(item.genre);
      return matchesQuery && matchesGenre;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Búsqueda')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _queryController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Búsqueda aquí',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: _queryController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(_queryController.clear),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: genres.map((g) {
                final selected = _selectedGenres.contains(g);
                return FilterChip(
                  label: Text(g),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _selectedGenres.add(g);
                    } else {
                      _selectedGenres.remove(g);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                // Año, Idioma y Duración quedan pendientes de conectar a datos reales.
                'Año · Idioma · Duración (próximamente)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: results.isEmpty
                  ? const Center(child: Text('No se encontraron resultados', style: TextStyle(color: Colors.grey)))
                  : GridView.builder(
                      itemCount: results.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.78,
                      ),
                      itemBuilder: (_, i) {
                        final item = results[i];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ContentDetailScreen(title: item.title)),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF0F4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
