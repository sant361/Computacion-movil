import 'package:flutter/material.dart';
import '../../data/catalog_item.dart';
import '../../state/app_state.dart';
import 'catalog_editor_screen.dart';
import 'analytics_panel_screen.dart';

class ContentPanelScreen extends StatefulWidget {
  const ContentPanelScreen({super.key});
  @override
  State<ContentPanelScreen> createState() => _ContentPanelScreenState();
}

class _ContentPanelScreenState extends State<ContentPanelScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await appState.refreshCatalog();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo actualizar el catálogo.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([CatalogItem? initial]) async {
    final result = await Navigator.push<CatalogItem>(
        context,
        MaterialPageRoute(
            builder: (_) => CatalogEditorScreen(initial: initial)));
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      if (initial == null) {
        await appState.addCatalogItem(result);
      } else {
        await appState.updateCatalogItem(result);
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Contenido guardado.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'No se pudo guardar. Revisa tu conexión y los permisos de tu cuenta.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(CatalogItem item) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
                title: const Text('¿Eliminar este contenido?'),
                content: Text(
                    'Se retirará «${item.title}» del catálogo para todos los usuarios.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Eliminar'))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await appState.deleteCatalogItem(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contenido eliminado.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'No se pudo eliminar. Revisa tu conexión y los permisos de tu cuenta.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: appState,
      builder: (context, _) => Scaffold(
            appBar: AppBar(title: const Text('Contenido'), actions: [
              if (appState.isAdmin) ...[
                IconButton(
                    tooltip: 'Estadísticas',
                    icon: const Icon(Icons.bar_chart),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AnalyticsPanelScreen()))),
                TextButton(
                    onPressed: _busy ? null : () => _edit(),
                    child: const Text('Nuevo')),
              ],
            ]),
            body: !appState.isAdmin
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'Esta sección está disponible para administradores.')))
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (_busy) const LinearProgressIndicator(),
                          if (_error != null ||
                              appState.catalogError != null) ...[
                            Text(_error ?? appState.catalogError!),
                            TextButton(
                                onPressed: _refresh,
                                child: const Text('Reintentar')),
                          ],
                          Row(children: [
                            Expanded(
                                child: Text(
                                    '${appState.adminCatalog.length} títulos')),
                            IconButton(
                                tooltip: 'Actualizar catálogo',
                                onPressed: _busy ? null : _refresh,
                                icon: const Icon(Icons.refresh))
                          ]),
                          if (appState.adminCatalog.isEmpty)
                            const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                    'Agrega el primer título del catálogo.')),
                          ...appState.adminCatalog.map((item) => Card(
                              child: ListTile(
                                  leading: item.posterUrl.isEmpty
                                      ? const Icon(Icons.movie_outlined)
                                      : SizedBox(
                                          width: 40,
                                          height: 56,
                                          child: Image.network(item.posterUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(Icons
                                                      .broken_image_outlined))),
                                  title: Text(item.title),
                                  subtitle: Text(
                                      '${item.genre} · ${item.year} · ${item.rating}'
                                      '${item.episodes.isEmpty ? '' : ' · ${item.episodes.length} episodios'}'),
                                  onTap: _busy ? null : () => _edit(item),
                                  trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                            tooltip: 'Editar ${item.title}',
                                            onPressed: _busy
                                                ? null
                                                : () => _edit(item),
                                            icon: const Icon(
                                                Icons.edit_outlined)),
                                        IconButton(
                                            tooltip: 'Eliminar ${item.title}',
                                            onPressed: _busy
                                                ? null
                                                : () => _delete(item),
                                            icon: const Icon(
                                                Icons.delete_outline)),
                                      ])))),
                        ])),
          ));
}
