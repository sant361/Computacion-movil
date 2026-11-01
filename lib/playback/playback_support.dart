import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
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

ClosedCaptionFile parseCaptionFile(String content) {
  final normalized = content.replaceFirst('\uFEFF', '').trimLeft();
  final file = normalized.startsWith('WEBVTT')
      ? WebVTTCaptionFile(normalized)
      : SubRipCaptionFile(normalized);
  if (file.captions.isEmpty) {
    throw const FormatException('El archivo no contiene subtítulos válidos.');
  }
  return file;
}

Future<ClosedCaptionFile> loadCaptionFile(String source,
    {http.Client? client}) async {
  if (source.startsWith('assets/')) {
    return parseCaptionFile(await rootBundle.loadString(source));
  }
  if (!isPlayableUrl(source)) {
    throw const FormatException('La dirección de subtítulos no es válida.');
  }
  final connection = client ?? http.Client();
  try {
    final response = await connection
        .get(Uri.parse(source))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw StateError('No se pudo descargar el archivo de subtítulos.');
    }
    if (response.bodyBytes.length > 2 * 1024 * 1024) {
      throw const FormatException(
          'El archivo de subtítulos es demasiado grande.');
    }
    return parseCaptionFile(utf8.decode(response.bodyBytes));
  } finally {
    if (client == null) connection.close();
  }
}

class CaptionPreferences {
  const CaptionPreferences({this.enabled = false, this.fontSize = 20});
  final bool enabled;
  final double fontSize;
  CaptionPreferences copyWith({bool? enabled, double? fontSize}) =>
      CaptionPreferences(
          enabled: enabled ?? this.enabled,
          fontSize: fontSize ?? this.fontSize);
}

class PlaybackSleepTimer extends ValueNotifier<Duration?> {
  PlaybackSleepTimer(this.onElapsed) : super(null);
  final VoidCallback onElapsed;
  Timer? _timer;
  void schedule(Duration? duration) {
    _timer?.cancel();
    value = duration;
    if (duration != null) {
      _timer = Timer(duration, () {
        value = null;
        onElapsed();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
