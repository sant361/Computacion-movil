import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../content_detail_screen.dart';

class ViewingHistoryScreen extends StatelessWidget {
  const ViewingHistoryScreen({super.key});

  Future<void> _clear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('¿Borrar el historial de este perfil?'),
              content: const Text(
                  'También se quitarán sus títulos de Seguir viendo.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Borrar historial')),
              ],
            ));
    if (confirmed == true) await appState.clearViewingHistory();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final entries = appState.viewingHistory
            .where((entry) =>
                appState.catalogItem(entry.title.split(' · T').first) != null)
            .toList();
        return Scaffold(
          appBar:
              AppBar(title: const Text('Historial de reproducción'), actions: [
            IconButton(
                tooltip: 'Borrar historial',
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: entries.isEmpty ? null : () => _clear(context)),
          ]),
          body: entries.isEmpty
              ? const Center(
                  child: Text('Aún no hay reproducciones en este perfil.'))
              : ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final item =
                        appState.catalogItem(entry.title.split(' · T').first)!;
                    final date =
                        DateTime.fromMicrosecondsSinceEpoch(entry.updatedAt);
                    final label = entry.updatedAt <= 1
                        ? 'Fecha no disponible'
                        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                    return ListTile(
                      leading: Icon(entry.completed
                          ? Icons.check_circle_outline
                          : Icons.history),
                      title: Text(entry.title),
                      subtitle: Text(
                          '${entry.completed ? 'Finalizado' : '${Duration(milliseconds: entry.positionMs).inMinutes} min reproducidos'} · $label'),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ContentDetailScreen(title: item.title))),
                    );
                  }),
        );
      });
}
