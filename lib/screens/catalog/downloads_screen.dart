import 'package:flutter/material.dart';

/// Req. 45, 46, 47: descargas para ver sin conexión y sus restricciones.
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final List<Map<String, Object>> _downloads = [
    {'titulo': 'Episodio 4', 'detalle': '124 MB · Descargado', 'progreso': 1.0},
    {'titulo': 'Episodio 5', 'detalle': 'Descargando · 62%', 'progreso': 0.62},
    {'titulo': 'Película X', 'detalle': 'En pausa · 30%', 'progreso': 0.30},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Descargas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._downloads.asMap().entries.map(
                (entry) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.value['titulo'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(entry.value['detalle'] as String,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => setState(() => _downloads.removeAt(entry.key)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(value: entry.value['progreso'] as double),
                      ],
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 8),
          const Text(
            'Límite de dispositivos y tiempo de disponibilidad según tu plan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              // TODO: navegar al catálogo para elegir qué descargar.
            },
            child: const Text('Descargar más contenido'),
          ),
        ],
      ),
    );
  }
}
