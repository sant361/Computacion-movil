import 'package:flutter/material.dart';
import 'content_detail_screen.dart';
import '../data/catalog_item.dart';
import '../state/app_state.dart';

/// Req. 36, 37: búsqueda y filtros (género, año, idioma y duración) sobre
/// el catálogo real (appState.catalog).
class SearchScreen extends StatefulWidget {
  /// Si se pasa, el filtro de género inicia ya seleccionado (por ejemplo al
  /// entrar aquí desde una categoría del Menú).
  final String? initialGenre;

  const SearchScreen({super.key, this.initialGenre});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

/// Duración corta/media/larga, en minutos. Son rangos fijos (no dependen
/// del catálogo) para que el filtro sea fácil de entender para quien usa
/// la app.
enum _DurationBucket {
  corto('Corto (<60 min)'),
  medio('Medio (60-100 min)'),
  largo('Largo (>100 min)');

  final String label;
  const _DurationBucket(this.label);

  bool matches(int minutes) => switch (this) {
        _DurationBucket.corto => minutes < 60,
        _DurationBucket.medio => minutes >= 60 && minutes <= 100,
        _DurationBucket.largo => minutes > 100,
      };
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryController = TextEditingController();
  final Set<String> _selectedGenres = {};
  final Set<int> _selectedYears = {};
  final Set<String> _selectedLanguages = {};
  final Set<_DurationBucket> _selectedDurations = {};

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
    return appState.catalog.where((item) {
      final matchesQuery = query.isEmpty || item.title.toLowerCase().contains(query);
      final matchesGenre = _selectedGenres.isEmpty || _selectedGenres.contains(item.genre);
      final matchesYear = _selectedYears.isEmpty || _selectedYears.contains(item.year);
      final matchesLanguage = _selectedLanguages.isEmpty || _selectedLanguages.contains(item.language);
      final matchesDuration = _selectedDurations.isEmpty ||
          _selectedDurations.any((bucket) => bucket.matches(item.durationMinutes));
      return matchesQuery && matchesGenre && matchesYear && matchesLanguage && matchesDuration;
    }).toList();
  }

  Widget _filterGroup<T>({
    required String label,
    required List<T> options,
    required Set<T> selected,
    required String Function(T) labelOf,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(labelOf(option)),
              selected: isSelected,
              onSelected: (v) => setState(() {
                if (v) {
                  selected.add(option);
                } else {
                  selected.remove(option);
                }
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    final catalog = appState.catalog;
    final years = catalog.map((e) => e.year).toSet().toList()..sort();
    final languages = catalog.map((e) => e.language).toSet().toList()..sort();

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
            SizedBox(
              height: 148,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _filterGroup<String>(
                      label: 'GÉNERO',
                      options: genres,
                      selected: _selectedGenres,
                      labelOf: (g) => g,
                    ),
                    const SizedBox(height: 8),
                    _filterGroup<int>(
                      label: 'AÑO',
                      options: years,
                      selected: _selectedYears,
                      labelOf: (y) => '$y',
                    ),
                    const SizedBox(height: 8),
                    _filterGroup<String>(
                      label: 'IDIOMA',
                      options: languages,
                      selected: _selectedLanguages,
                      labelOf: (l) => l,
                    ),
                    const SizedBox(height: 8),
                    _filterGroup<_DurationBucket>(
                      label: 'DURACIÓN',
                      options: _DurationBucket.values,
                      selected: _selectedDurations,
                      labelOf: (d) => d.label,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
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
