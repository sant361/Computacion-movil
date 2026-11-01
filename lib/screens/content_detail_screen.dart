import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/catalog_item.dart';
import '../playback/playback_support.dart';
import '../state/app_state.dart';
import 'player_screen.dart';

class ContentDetailScreen extends StatefulWidget {
  const ContentDetailScreen({super.key, this.title = 'Título de la serie'});
  final String title;
  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  int? _season;
  bool? _liked;

  void _play(CatalogItem item, {CatalogEpisode? episode}) {
    if (appState.catalogItem(item.title) == null) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                PlayerScreen(contentTitle: item.title, episode: episode)));
  }

  CatalogEpisode? _resumeEpisode(CatalogItem item) {
    final episodes = orderedEpisodes(item);
    if (episodes.isEmpty) return null;
    final pending = episodes
        .where((entry) =>
            appState.watchProgress(entry.progressKey(item.title)) != null)
        .toList()
      ..sort((a, b) => appState
          .watchProgress(b.progressKey(item.title))!
          .updatedAt
          .compareTo(
              appState.watchProgress(a.progressKey(item.title))!.updatedAt));
    return pending.isNotEmpty ? pending.first : episodes.first;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final item = appState.catalogItem(widget.title);
          if (item == null) {
            return Scaffold(
                appBar: AppBar(title: const Text('Contenido no disponible')),
                body: const Center(
                    child: Text(
                        'Este contenido no está disponible para este perfil.')));
          }
          final episodes = orderedEpisodes(item);
          final seasons = episodes.map((entry) => entry.season).toSet().toList()
            ..sort();
          final season =
              seasons.contains(_season) ? _season : seasons.firstOrNull;
          final start = _resumeEpisode(item);
          final progress = appState
              .watchProgress(start?.progressKey(item.title) ?? item.title);
          final playable = isPlayableUrl(start?.videoUrl ?? item.videoUrl);
          final liked = _liked;
          return Scaffold(
              body: CustomScrollView(slivers: [
            const SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                    background: ColoredBox(
                        color: Color(0xFF132237),
                        child: Center(
                            child: Icon(Icons.movie_outlined,
                                size: 64, color: Colors.white70))))),
            SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                    delegate: SliverChildListDelegate([
                  Text(item.title,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                      '${item.year} · ${item.genre} · ${item.language} · ${item.rating}',
                      style: const TextStyle(color: Colors.grey)),
                  if (episodes.isEmpty) Text('${item.durationMinutes} minutos'),
                  const SizedBox(height: 16),
                  Text(item.description.isEmpty
                      ? 'La sinopsis todavía no está disponible.'
                      : item.description),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                          progress == null ? 'REPRODUCIR' : 'CONTINUAR VIENDO'),
                      onPressed:
                          playable ? () => _play(item, episode: start) : null),
                  if (!playable)
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('El video todavía no está disponible.')),
                  Row(children: [
                    Expanded(
                        child: OutlinedButton.icon(
                            icon: Icon(appState.isInMyList(item.title)
                                ? Icons.favorite
                                : Icons.favorite_border),
                            label: Text(appState.isInMyList(item.title)
                                ? 'En mi lista'
                                : 'Mi lista'),
                            onPressed: () =>
                                appState.toggleMyList(item.title))),
                    IconButton(
                        tooltip: 'Me gusta',
                        icon: Icon(liked == true
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined),
                        onPressed: () => setState(
                            () => _liked = liked == true ? null : true)),
                    IconButton(
                        tooltip: 'No me gusta',
                        icon: Icon(liked == false
                            ? Icons.thumb_down
                            : Icons.thumb_down_outlined),
                        onPressed: () => setState(
                            () => _liked = liked == false ? null : false)),
                  ]),
                  Row(children: [
                    Expanded(
                        child: OutlinedButton.icon(
                            icon: const Icon(Icons.share),
                            label: const Text('Copiar título'),
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(
                                  text: '${item.title} — +Wnovelas'));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Título copiado para compartir.')));
                              }
                            })),
                  ]),
                  OutlinedButton.icon(
                    icon: Icon(appState.isDownloaded(item.title)
                        ? Icons.check_circle
                        : Icons.download_outlined),
                    label: Text(appState.isDownloaded(item.title)
                        ? 'En descargas'
                        : 'Guardar en descargas'),
                    onPressed: appState.isDownloaded(item.title)
                        ? null
                        : () {
                            appState.downloadContent(item.title);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Agregado a Descargas.')));
                          },
                  ),
                  if (episodes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                        value: season,
                        decoration:
                            const InputDecoration(labelText: 'Temporada'),
                        items: seasons
                            .map((number) => DropdownMenuItem(
                                value: number,
                                child: Text('Temporada $number')))
                            .toList(),
                        onChanged: (value) => setState(() => _season = value)),
                    const SizedBox(height: 8),
                    ...episodes
                        .where((entry) => entry.season == season)
                        .map((episode) {
                      final episodeProgress = appState
                          .watchProgress(episode.progressKey(item.title));
                      return Card(
                          child: Column(children: [
                        ListTile(
                            title: Text('${episode.number}. ${episode.title}'),
                            subtitle: Text(episodeProgress == null
                                ? '${episode.durationMinutes} minutos'
                                : 'Continuar desde ${formatPlaybackTime(Duration(milliseconds: episodeProgress.positionMs))}'),
                            trailing: const Icon(Icons.play_circle_outline),
                            enabled: isPlayableUrl(episode.videoUrl),
                            onTap: isPlayableUrl(episode.videoUrl)
                                ? () => _play(item, episode: episode)
                                : null),
                        if (episodeProgress != null)
                          LinearProgressIndicator(
                              value: episodeProgress.fraction),
                      ]));
                    }),
                  ],
                ]))),
          ]));
        });
  }
}
