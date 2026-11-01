import '../data/catalog_item.dart';

List<CatalogEpisode> orderedEpisodes(CatalogItem item) {
  final episodes = List<CatalogEpisode>.of(item.episodes);
  episodes.sort((a, b) {
    final season = a.season.compareTo(b.season);
    return season != 0 ? season : a.number.compareTo(b.number);
  });
  return episodes;
}

CatalogEpisode? nextEpisode(CatalogItem item, CatalogEpisode? current) {
  if (current == null) return null;
  final episodes = orderedEpisodes(item);
  final index = episodes.indexWhere((episode) =>
      episode.progressKey(item.title) == current.progressKey(item.title));
  return index >= 0 && index + 1 < episodes.length ? episodes[index + 1] : null;
}

bool isPlayableUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty;
}

String formatPlaybackTime(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
