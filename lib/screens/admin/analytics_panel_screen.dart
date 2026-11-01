import 'package:flutter/material.dart';
import '../../state/app_state.dart';

class AnalyticsPanelScreen extends StatefulWidget {
  const AnalyticsPanelScreen({super.key});
  @override
  State<AnalyticsPanelScreen> createState() => _AnalyticsPanelScreenState();
}

class _AnalyticsPanelScreenState extends State<AnalyticsPanelScreen> {
  Future<List<Map<String, dynamic>>>? _statistics;

  @override
  Widget build(BuildContext context) {
    if (!appState.isAdmin) {
      return Scaffold(
          appBar: AppBar(title: const Text('Estadísticas')),
          body: const Center(
              child:
                  Text('Esta sección está disponible para administradores.')));
    }
    _statistics ??= appState.catalogStatistics();
    return Scaffold(
        appBar: AppBar(title: const Text('Estadísticas'), actions: [
          IconButton(
              tooltip: 'Actualizar estadísticas',
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  setState(() => _statistics = appState.catalogStatistics())),
        ]),
        body: FutureBuilder<List<Map<String, dynamic>>>(
            future: _statistics,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('No se pudieron cargar las estadísticas.'),
                  TextButton(
                      onPressed: () => setState(
                          () => _statistics = appState.catalogStatistics()),
                      child: const Text('Reintentar')),
                ]));
              }
              final rows = snapshot.data ?? [];
              final genres = <String, int>{};
              var total = 0;
              for (final row in rows) {
                final plays = (row['plays'] as num?)?.toInt() ?? 0;
                final genre = row['genre'] as String? ?? 'Sin género';
                genres[genre] = (genres[genre] ?? 0) + plays;
                total += plays;
              }
              final ordered = genres.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              return ListView(padding: const EdgeInsets.all(16), children: [
                Text('$total reproducciones registradas',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),
                if (rows.isEmpty)
                  const Text(
                      'Las estadísticas aparecerán cuando se reproduzca contenido.'),
                const Text('Géneros más vistos',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...ordered.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${entry.key}: ${entry.value}'),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                              value: total == 0 ? 0 : entry.value / total,
                              minHeight: 8,
                              semanticsLabel:
                                  '${entry.key}, ${entry.value} reproducciones'),
                        ]))),
                const SizedBox(height: 24),
                const Text('Títulos más vistos',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...rows.map((row) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(row['title'] as String? ?? ''),
                    subtitle: Text(row['genre'] as String? ?? ''),
                    trailing: Text('${row['plays'] ?? 0} reproducciones'))),
              ]);
            }));
  }
}
