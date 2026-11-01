import 'package:flutter/material.dart';
import '../data/catalog_item.dart';
import '../state/app_state.dart';
import 'content_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialGenre;
  const SearchScreen({super.key, this.initialGenre});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

enum _DurationBucket {
  corto('Menos de 60 min'),
  medio('60 a 100 min'),
  largo('Más de 100 min');

  final String label;
  const _DurationBucket(this.label);

  bool matches(int minutes) => switch (this) {
        _DurationBucket.corto => minutes < 60,
        _DurationBucket.medio => minutes >= 60 && minutes <= 100,
        _DurationBucket.largo => minutes > 100,
      };
}

class _SearchScreenState extends State<SearchScreen> {
  static const background = Color(0xFF07111F);
  static const surface = Color(0xFF142338);
  static const accent = Color(0xFF35D0C4);
  final _queryController = TextEditingController();
  final _selectedGenres = <String>{};
  final _selectedYears = <int>{};
  final _selectedLanguages = <String>{};
  final _selectedDurations = <_DurationBucket>{};
  bool _showFilters = false;

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

  int get _filterCount =>
      _selectedGenres.length +
      _selectedYears.length +
      _selectedLanguages.length +
      _selectedDurations.length;

  void _clearFilters() => setState(() {
        _selectedGenres.clear();
        _selectedYears.clear();
        _selectedLanguages.clear();
        _selectedDurations.clear();
      });

  String _normalize(String value) {
    const from = 'áéíóúüñ';
    const to = 'aeiouun';
    return value.trim().toLowerCase().split('').map((character) {
      final index = from.indexOf(character);
      return index < 0 ? character : to[index];
    }).join();
  }

  List<CatalogItem> _results(List<CatalogItem> catalog) {
    final query = _normalize(_queryController.text);
    return catalog
        .where((item) =>
            (query.isEmpty || _normalize(item.title).contains(query)) &&
            (_selectedGenres.isEmpty || _selectedGenres.contains(item.genre)) &&
            (_selectedYears.isEmpty || _selectedYears.contains(item.year)) &&
            (_selectedLanguages.isEmpty ||
                _selectedLanguages.contains(item.language)) &&
            (_selectedDurations.isEmpty ||
                _selectedDurations.any((d) => d.matches(item.durationMinutes))))
        .toList();
  }

  Widget _filterGroup<T>(String title, List<T> options, Set<T> selected) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final active = selected.contains(option);
              final label =
                  option is _DurationBucket ? option.label : '$option';
              return FilterChip(
                label: Text(label),
                selected: active,
                showCheckmark: false,
                backgroundColor: surface,
                selectedColor: accent,
                side: BorderSide.none,
                labelStyle: TextStyle(
                    color: active ? background : Colors.white,
                    fontWeight: FontWeight.w600),
                onSelected: (value) => setState(() {
                  if (value) {
                    selected.add(option);
                  } else {
                    selected.remove(option);
                  }
                }),
              );
            }).toList()),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final catalog = appState.catalog;
          final results = _results(catalog);
          final genres = catalog.map((e) => e.genre).toSet().toList()..sort();
          final years = catalog.map((e) => e.year).toSet().toList()..sort();
          final languages = catalog.map((e) => e.language).toSet().toList()
            ..sort();
          final query = _queryController.text.trim();
          return Scaffold(
            backgroundColor: background,
            appBar: AppBar(
              backgroundColor: background,
              foregroundColor: Colors.white,
              title: const Text('Buscar',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            body: SafeArea(
                child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  sliver: SliverList.list(children: [
                    TextField(
                      controller: _queryController,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: accent,
                      decoration: InputDecoration(
                        hintText: 'Busca una película o serie',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon:
                            const Icon(Icons.search_rounded, color: accent),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Borrar búsqueda',
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.white70),
                                onPressed: () =>
                                    setState(_queryController.clear),
                              ),
                        filled: true,
                        fillColor: surface,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => _showFilters = !_showFilters),
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: Text(_filterCount == 0
                            ? 'Filtros'
                            : 'Filtros ($_filterCount)'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: accent,
                            side: const BorderSide(color: accent)),
                      ),
                      if (_filterCount > 0) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _clearFilters,
                          style: TextButton.styleFrom(foregroundColor: accent),
                          child: const Text('Limpiar filtros'),
                        ),
                      ],
                    ]),
                    if (_showFilters) ...[
                      const SizedBox(height: 12),
                      _filterGroup('GÉNERO', genres, _selectedGenres),
                      _filterGroup('AÑO', years, _selectedYears),
                      _filterGroup('IDIOMA', languages, _selectedLanguages),
                      _filterGroup('DURACIÓN', _DurationBucket.values,
                          _selectedDurations),
                    ],
                    const SizedBox(height: 14),
                    Text(
                        query.isEmpty
                            ? 'Explora el catálogo'
                            : 'Resultados para “$query”',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                        '${results.length} ${results.length == 1 ? 'título' : 'títulos'}',
                        style: const TextStyle(color: Colors.white60)),
                    const SizedBox(height: 16),
                  ]),
                ),
                if (results.isEmpty)
                  SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                          child: Padding(
                        padding: const EdgeInsets.all(24),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.movie_filter_outlined,
                              color: accent, size: 48),
                          const SizedBox(height: 12),
                          const Text('No encontramos títulos',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(
                              query.isEmpty
                                  ? 'Prueba con otros filtros.'
                                  : 'Prueba con otro nombre o limpia los filtros.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white60)),
                          if (_filterCount > 0)
                            TextButton(
                              onPressed: _clearFilters,
                              style:
                                  TextButton.styleFrom(foregroundColor: accent),
                              child: const Text('Limpiar filtros'),
                            ),
                        ]),
                      )))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverLayoutBuilder(
                        builder: (context, constraints) => SliverGrid.builder(
                              itemCount: results.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    constraints.crossAxisExtent >= 600 ? 3 : 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.76,
                              ),
                              itemBuilder: (context, index) =>
                                  _ResultCard(item: results[index]),
                            )),
                  ),
              ],
            )),
          );
        },
      );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.item});
  final CatalogItem item;

  @override
  Widget build(BuildContext context) {
    final colors = switch (item.genre) {
      'Comedia' => const [Color(0xFF8B4A80), Color(0xFF382653)],
      'Suspenso' => const [Color(0xFF427C92), Color(0xFF182843)],
      'Acción' => const [Color(0xFFCA7146), Color(0xFF512D48)],
      'Infantil' => const [Color(0xFF36A6A1), Color(0xFF24517C)],
      'Romance' => const [Color(0xFFBF637D), Color(0xFF593954)],
      _ => const [Color(0xFF5570A6), Color(0xFF28314F)],
    };
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ContentDetailScreen(title: item.title))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors)),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: const Stack(fit: StackFit.expand, children: [
                Center(
                    child: Icon(Icons.play_circle_fill_rounded,
                        color: Colors.white, size: 42)),
              ])),
        )),
        const SizedBox(height: 8),
        Text(item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text('${item.genre} · ${item.year}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ]),
    );
  }
}
