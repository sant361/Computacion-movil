import 'package:flutter/material.dart';
import '../../data/catalog_item.dart';

class CatalogEditorScreen extends StatefulWidget {
  const CatalogEditorScreen({super.key, this.initial});
  final CatalogItem? initial;

  @override
  State<CatalogEditorScreen> createState() => _CatalogEditorScreenState();
}

class _CatalogEditorScreenState extends State<CatalogEditorScreen> {
  final _form = GlobalKey<FormState>();
  late String _title, _description, _genre, _language, _rating;
  late String _video, _trailer, _poster, _subtitles, _year, _duration;
  late List<CatalogEpisode> _episodes;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _title = item?.title ?? '';
    _description = item?.description ?? '';
    _genre = item?.genre ?? 'Comedia';
    _language = item?.language ?? 'Español';
    _rating = item?.rating ?? 'TP';
    _video = item?.videoUrl ?? '';
    _trailer = item?.trailerUrl ?? '';
    _poster = item?.posterUrl ?? '';
    _subtitles = item?.subtitleUrl ?? '';
    _year = '${item?.year ?? DateTime.now().year}';
    _duration = '${item?.durationMinutes ?? 90}';
    _episodes = [...?item?.episodes];
  }

  String? _url(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
            ['http', 'https'].contains(uri.scheme) &&
            uri.host.isNotEmpty
        ? null
        : 'Escribe una URL http o https válida.';
  }

  Future<void> _editEpisode([CatalogEpisode? episode]) async {
    final result = await showDialog<CatalogEpisode>(
        context: context,
        builder: (_) => EpisodeEditorDialog(initial: episode));
    if (result == null || !mounted) return;
    final duplicate = _episodes.any((item) =>
        !identical(item, episode) &&
        item.season == result.season &&
        item.number == result.number);
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ya existe ese capítulo en la temporada.')));
      return;
    }
    setState(() {
      if (episode == null) {
        _episodes.add(result);
      } else {
        _episodes[_episodes.indexOf(episode)] = result;
      }
      _episodes.sort((a, b) {
        final season = a.season.compareTo(b.season);
        return season != 0 ? season : a.number.compareTo(b.number);
      });
    });
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    if (_video.trim().isEmpty && _episodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Agrega el video de la película o al menos un episodio.')));
      return;
    }
    final item = CatalogItem(
        id: widget.initial?.id ?? '',
        title: _title.trim(),
        genre: _genre,
        year: int.tryParse(_year) ?? 0,
        language: _language,
        durationMinutes: int.tryParse(_duration) ?? 0,
        description: _description.trim(),
        videoUrl: _video.trim(),
        trailerUrl: _trailer.trim(),
        posterUrl: _poster.trim(),
        subtitleUrl: _subtitles.trim(),
        ageRating: _rating,
        episodes: List.unmodifiable(_episodes));
    final error = item.validationError;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pop(context, item);
  }

  Widget _text(String label, String value, ValueChanged<String> changed,
          {String? Function(String?)? validator,
          int lines = 1,
          bool number = false}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
              key: ValueKey('catalog-$label'),
              initialValue: value,
              onChanged: changed,
              maxLines: lines,
              keyboardType: number ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(labelText: label),
              validator: validator));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
              widget.initial == null ? 'Nuevo contenido' : 'Editar contenido'),
          actions: [
            TextButton(onPressed: _save, child: const Text('Guardar'))
          ]),
      body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            _text('Título', _title, (v) => _title = v,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Escribe un título.'
                    : null),
            _text('Sinopsis', _description, (v) => _description = v, lines: 4),
            DropdownButtonFormField<String>(
                value: _genre,
                decoration: const InputDecoration(labelText: 'Género'),
                items: {
                  'Comedia',
                  'Suspenso',
                  'Acción',
                  'Infantil',
                  'Romance',
                  _genre
                }
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _genre = v ?? _genre)),
            DropdownButtonFormField<String>(
                value: _language,
                decoration: const InputDecoration(labelText: 'Idioma'),
                items: {'Español', 'Inglés', 'Francés', 'Portugués', _language}
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _language = v ?? _language)),
            DropdownButtonFormField<String>(
                value: _rating,
                decoration:
                    const InputDecoration(labelText: 'Clasificación por edad'),
                items: parentalRatings
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _rating = v ?? _rating)),
            _text('Año', _year, (v) => _year = v, number: true, validator: (v) {
              final year = int.tryParse(v ?? '');
              return year != null &&
                      year >= 1900 &&
                      year <= DateTime.now().year + 1
                  ? null
                  : 'Revisa el año.';
            }),
            _text('Duración en minutos', _duration, (v) => _duration = v,
                number: true,
                validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                    ? null
                    : 'Escribe una duración válida.'),
            _text('URL del video', _video, (v) => _video = v, validator: _url),
            _text('URL del tráiler', _trailer, (v) => _trailer = v,
                validator: _url),
            _text('URL de la portada', _poster, (v) => _poster = v,
                validator: _url),
            _text('URL de subtítulos', _subtitles, (v) => _subtitles = v,
                validator: _url),
            const SizedBox(height: 16),
            Row(children: [
              const Expanded(
                  child: Text('Temporadas y episodios',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              IconButton(
                  tooltip: 'Agregar episodio',
                  onPressed: () => _editEpisode(),
                  icon: const Icon(Icons.add))
            ]),
            if (_episodes.isEmpty)
              const Text(
                  'Sin episodios. Usa el video principal para una película.'),
            ..._episodes.map((episode) => Card(
                child: ListTile(
                    title: Text(
                        'T${episode.season} · E${episode.number} · ${episode.title}'),
                    subtitle: Text('${episode.durationMinutes} minutos'),
                    onTap: () => _editEpisode(episode),
                    trailing: IconButton(
                        tooltip: 'Quitar episodio',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            setState(() => _episodes.remove(episode)))))),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: _save, child: const Text('Guardar contenido')),
          ])),
    );
  }
}

class EpisodeEditorDialog extends StatefulWidget {
  const EpisodeEditorDialog({super.key, this.initial});
  final CatalogEpisode? initial;
  @override
  State<EpisodeEditorDialog> createState() => _EpisodeEditorDialogState();
}

class _EpisodeEditorDialogState extends State<EpisodeEditorDialog> {
  final _form = GlobalKey<FormState>();
  late String _title, _video, _subtitles, _season, _number, _duration;
  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    _title = e?.title ?? '';
    _video = e?.videoUrl ?? '';
    _subtitles = e?.subtitleUrl ?? '';
    _season = '${e?.season ?? 1}';
    _number = '${e?.number ?? 1}';
    _duration = '${e?.durationMinutes ?? 24}';
  }

  String? _positive(String? value) => (int.tryParse(value ?? '') ?? 0) > 0
      ? null
      : 'Escribe un número mayor que cero.';
  String? _url(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    return uri != null &&
            ['https', 'http'].contains(uri.scheme) &&
            uri.host.isNotEmpty
        ? null
        : 'Escribe una URL http o https válida.';
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
        context,
        CatalogEpisode(
            id: widget.initial?.id.isNotEmpty == true
                ? widget.initial!.id
                : 'episode-${DateTime.now().microsecondsSinceEpoch}',
            title: _title.trim(),
            videoUrl: _video.trim(),
            subtitleUrl: _subtitles.trim(),
            season: int.parse(_season),
            number: int.parse(_number),
            durationMinutes: int.parse(_duration)));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text(
              widget.initial == null ? 'Nuevo episodio' : 'Editar episodio'),
          content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                  child: Form(
                      key: _form,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        TextFormField(
                            initialValue: _title,
                            decoration: const InputDecoration(
                                labelText: 'Título del episodio'),
                            onChanged: (v) => _title = v,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Escribe un título.'
                                : null),
                        TextFormField(
                            initialValue: _season,
                            decoration:
                                const InputDecoration(labelText: 'Temporada'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => _season = v,
                            validator: _positive),
                        TextFormField(
                            initialValue: _number,
                            decoration: const InputDecoration(
                                labelText: 'Número de episodio'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => _number = v,
                            validator: _positive),
                        TextFormField(
                            initialValue: _duration,
                            decoration: const InputDecoration(
                                labelText: 'Duración en minutos'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => _duration = v,
                            validator: _positive),
                        TextFormField(
                            initialValue: _video,
                            decoration: const InputDecoration(
                                labelText: 'URL del video del episodio'),
                            onChanged: (v) => _video = v,
                            validator: _url),
                        TextFormField(
                            initialValue: _subtitles,
                            decoration: const InputDecoration(
                                labelText: 'URL de subtítulos del episodio'),
                            onChanged: (v) => _subtitles = v,
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? null : _url(v)),
                      ])))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            TextButton(onPressed: _save, child: const Text('Guardar episodio'))
          ]);
}
