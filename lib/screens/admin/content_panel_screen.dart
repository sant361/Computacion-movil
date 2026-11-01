import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/catalog_item.dart';
import '../../state/app_state.dart';

/// Req. 52, 53: administración de contenido, temporadas y episodios.
class ContentPanelScreen extends StatelessWidget {
  const ContentPanelScreen({super.key});

  static const items = [
    {'nombre': 'Serie A', 'estado': 'Publicado', 'color': Colors.green},
    {'nombre': 'Película B', 'estado': 'Revisión', 'color': Colors.orange},
    {'nombre': 'Serie C', 'estado': 'Borrador', 'color': Colors.grey},
  ];

  Future<void> _addContent(BuildContext context) async {
    if (!appState.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Solo los administradores pueden agregar contenido.')),
      );
      return;
    }
    final item = await showDialog<CatalogItem>(
      context: context,
      builder: (_) => const _NewContentDialog(),
    );
    if (item == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await appState.addCatalogItem(item);
      messenger.showSnackBar(
          SnackBar(content: Text('"${item.title}" agregado al catálogo')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text(
                'No se pudo guardar. Revisa tu conexión e intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contenido'),
        actions: [
          TextButton(
            onPressed: () => _addContent(context),
            child: const Text('+ Nuevo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...items.map(
            (c) => Card(
              child: ListTile(
                leading: Container(
                    width: 40, height: 40, color: const Color(0xFFEEF0F4)),
                title: Text(c['nombre'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Chip(
                  label: Text(c['estado'] as String,
                      style: TextStyle(color: c['color'] as Color)),
                  visualDensity: VisualDensity.compact,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text('Editar contenido (demo)')))),
                    IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text('Contenido eliminado (demo)')))),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 32),
          const Text('Temporadas y episodios',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Abriendo panel de temporadas (demo)'))),
              child: const Text('Panel de temporadas')),
          const SizedBox(height: 8),
          OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Abriendo panel de episodios (demo)'))),
              child: const Text('Panel de episodios')),
          const SizedBox(height: 8),
          OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Abriendo formulario de carga (demo)'))),
              child: const Text('Formulario de carga multimedia')),
          const SizedBox(height: 16),
          const Center(
            child: Text('Estados: borrador · revisión · programado',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

/// Formulario para cargar un contenido nuevo al catálogo.
class _NewContentDialog extends StatefulWidget {
  const _NewContentDialog();

  @override
  State<_NewContentDialog> createState() => _NewContentDialogState();
}

class _NewContentDialogState extends State<_NewContentDialog> {
  static const _genres = [
    'Comedia',
    'Suspenso',
    'Acción',
    'Infantil',
    'Romance'
  ];
  static const _languages = ['Español', 'Inglés', 'Francés'];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _videoController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _yearController = TextEditingController(text: '${DateTime.now().year}');
  final _durationController = TextEditingController(text: '90');
  String _genre = _genres.first;
  String _language = _languages.first;

  @override
  void dispose() {
    _titleController.dispose();
    _videoController.dispose();
    _descriptionController.dispose();
    _yearController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      CatalogItem(
        title: _titleController.text.trim(),
        videoUrl: _videoController.text.trim(),
        description: _descriptionController.text.trim(),
        genre: _genre,
        year: int.parse(_yearController.text.trim()),
        language: _language,
        durationMinutes: int.parse(_durationController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo contenido'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Escribe un título'
                    : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Sinopsis'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _videoController,
                decoration: const InputDecoration(labelText: 'URL del video'),
                keyboardType: TextInputType.url,
                validator: (value) {
                  final uri = Uri.tryParse(value?.trim() ?? '');
                  return uri != null &&
                          ['http', 'https'].contains(uri.scheme) &&
                          uri.host.isNotEmpty
                      ? null
                      : 'Escribe una URL http o https válida.';
                },
              ),
              DropdownButtonFormField<String>(
                value: _genre,
                decoration: const InputDecoration(labelText: 'Género'),
                items: _genres
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _genre = v ?? _genre),
              ),
              DropdownButtonFormField<String>(
                value: _language,
                decoration: const InputDecoration(labelText: 'Idioma'),
                items: _languages
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setState(() => _language = v ?? _language),
              ),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Año'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                validator: (v) {
                  final year = int.tryParse(v ?? '');
                  if (year == null ||
                      year < 1900 ||
                      year > DateTime.now().year + 1) {
                    return 'Año no válido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _durationController,
                decoration:
                    const InputDecoration(labelText: 'Duración (minutos)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 3,
                validator: (v) {
                  final minutes = int.tryParse(v ?? '');
                  if (minutes == null || minutes < 1) {
                    return 'Duración no válida';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        TextButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}
