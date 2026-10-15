import 'package:flutter/material.dart';
import '../../state/app_state.dart';

/// Req. 45, 46, 47: descargas para ver sin conexión (conectado a AppState).
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Descargas')),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final downloads = appState.downloads;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (downloads.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Todavía no has descargado nada.\nBusca un contenido y toca "Descargar".',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...downloads.map(
                  (title) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Descargado'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => appState.removeDownload(title),
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
            ],
          );
        },
      ),
    );
  }
}
