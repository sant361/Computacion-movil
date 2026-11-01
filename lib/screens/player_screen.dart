import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../data/catalog_item.dart';
import '../playback/playback_support.dart';
import '../state/app_state.dart';
import 'fullscreen_player_screen.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen(
      {super.key,
      this.contentTitle = 'Serie · Temporada 1',
      this.episode,
      this.trailer = false,
      this.controllerFactory});
  final String contentTitle;
  final CatalogEpisode? episode;
  final bool trailer;
  final VideoPlayerController Function(Uri)? controllerFactory;
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  CatalogItem? _item;
  CatalogEpisode? _episode;
  late final String _playbackScope;
  final _captions = ValueNotifier(const CaptionPreferences());
  late final PlaybackSleepTimer _sleepTimer;
  bool _autoplay = true;
  bool _ready = false;
  bool _switching = false;
  bool _completionHandled = false;
  bool _wasPlaying = false;
  bool _fullscreenOpen = false;
  bool _nextPending = false;
  bool _loadingCaptions = false;
  int _lastSavedSecond = -1;
  int _generation = 0;
  String? _error;
  String? _captionError;
  String? _accessError;

  String get _progressKey =>
      _episode?.progressKey(_item!.title) ?? _item!.title;
  String get _subtitleSource =>
      widget.trailer ? '' : (_episode?.subtitleUrl ?? _item?.subtitleUrl ?? '');
  bool get _canControl =>
      _ready && !_switching && _accessError == null && _error == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _playbackScope = appState.playbackScope;
    _sleepTimer = PlaybackSleepTimer(() {
      _controller?.pause();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('La reproducción se detuvo por el temporizador.')));
      }
    });
    appState.addListener(_onAppChanged);
    _item = appState.catalogItem(widget.contentTitle);
    final item = _item;
    if (item == null) {
      _accessError = 'Este contenido no está disponible para este perfil.';
      return;
    }
    if (!widget.trailer && item.episodes.isNotEmpty) {
      final requested = widget.episode;
      final episodes = orderedEpisodes(item);
      if (requested != null) {
        _episode = episodes
            .where((entry) =>
                entry.progressKey(item.title) ==
                requested.progressKey(item.title))
            .firstOrNull;
        if (_episode == null) {
          _error = 'El episodio ya no está disponible.';
          return;
        }
      } else {
        final pending = episodes
            .where((entry) =>
                appState.watchProgress(entry.progressKey(item.title)) != null)
            .toList()
          ..sort((a, b) => appState
              .watchProgress(b.progressKey(item.title))!
              .updatedAt
              .compareTo(appState
                  .watchProgress(a.progressKey(item.title))!
                  .updatedAt));
        _episode = pending.isNotEmpty ? pending.first : episodes.first;
      }
    }
    unawaited(_openVideo());
  }

  void _onAppChanged() {
    if (!mounted) return;
    final current = appState.catalogItem(widget.contentTitle);
    final episodeRemoved = _episode != null &&
        current != null &&
        !current.episodes.any((entry) =>
            entry.progressKey(current.title) ==
            _episode!.progressKey(_item!.title));
    if (_accessError == null &&
        (_playbackScope != appState.playbackScope ||
            current == null ||
            episodeRemoved)) {
      _accessError = 'El perfil cambió o ya no tiene acceso a este contenido.';
      _controller?.pause();
      if (_fullscreenOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _fullscreenOpen) Navigator.of(context).pop();
        });
      }
    }
    setState(() {});
  }

  Future<void> _openVideo() async {
    final item = _item;
    if (item == null) return;
    final source = widget.trailer
        ? item.trailerUrl
        : (_episode?.videoUrl ?? item.videoUrl);
    if (!isPlayableUrl(source)) {
      if (mounted) {
        setState(() => _error = widget.trailer
            ? 'Este título todavía no tiene un tráiler disponible.'
            : 'Este título todavía no tiene un video disponible.');
      }
      return;
    }
    final generation = ++_generation;
    final controller = widget.controllerFactory?.call(Uri.parse(source)) ??
        VideoPlayerController.networkUrl(Uri.parse(source));
    _controller = controller;
    controller.addListener(_onPlaybackChanged);
    try {
      final saved = widget.trailer
          ? null
          : await appState.prepareWatchProgress(_progressKey);
      if (!mounted || generation != _generation) return;
      await controller.initialize().timeout(const Duration(seconds: 20));
      if (!mounted || generation != _generation) return;
      if (saved != null &&
          saved.positionMs < controller.value.duration.inMilliseconds) {
        await controller.seekTo(Duration(milliseconds: saved.positionMs));
      }
      if (!mounted || generation != _generation) return;
      setState(() {
        _ready = true;
        _error = null;
      });
      if (_accessError == null) await controller.play();
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _error =
            'No se pudo cargar el video. Revisa tu conexión y vuelve a intentarlo.');
      }
    }
  }

  void _onPlaybackChanged() {
    if (!mounted) return;
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.hasError && _error == null) {
      _error =
          'La reproducción se interrumpió. Revisa tu conexión y vuelve a intentarlo.';
    }
    final stopped = _wasPlaying && !controller.value.isPlaying;
    _wasPlaying = controller.value.isPlaying;
    if (_ready && stopped) unawaited(_saveProgress(sync: true));
    final second = controller.value.position.inSeconds;
    if (_ready && second != _lastSavedSecond) {
      _lastSavedSecond = second;
      unawaited(_saveProgress());
    }
    final duration = controller.value.duration;
    if (_completionHandled &&
        !_switching &&
        controller.value.position <
            duration - const Duration(milliseconds: 500)) {
      _completionHandled = false;
    }
    if (_ready &&
        !_completionHandled &&
        duration > Duration.zero &&
        controller.value.position >= duration) {
      _completionHandled = true;
      unawaited(_saveProgress(sync: true));
      if (_autoplay &&
          !widget.trailer &&
          nextEpisode(_item!, _episode) != null &&
          _accessError == null) {
        unawaited(_playNext());
      }
    }
    setState(() {});
  }

  Future<void> _saveProgress({bool sync = false}) async {
    final controller = _controller;
    if (!_ready ||
        widget.trailer ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }
    try {
      await appState.saveWatchProgress(
          _progressKey, controller.value.position, controller.value.duration,
          scope: _playbackScope);
      if (sync) unawaited(appState.syncWatchProgress());
    } catch (_) {}
  }

  Future<void> _playNext() async {
    if (_switching || !_canControl || widget.trailer) return;
    final next = nextEpisode(_item!, _episode);
    if (next == null) return;
    if (_fullscreenOpen) {
      _nextPending = true;
      Navigator.of(context).pop();
      return;
    }
    setState(() => _switching = true);
    await _saveProgress(sync: true);
    if (!mounted) return;
    final old = _controller;
    old?.removeListener(_onPlaybackChanged);
    if (old != null) unawaited(old.dispose());
    if (!mounted) return;
    setState(() {
      _episode = next;
      _controller = null;
      _ready = false;
      _completionHandled = false;
      _wasPlaying = false;
      _lastSavedSecond = -1;
      _error = null;
      _captionError = null;
      _captions.value = const CaptionPreferences();
      _switching = false;
    });
    await _openVideo();
  }

  Future<void> _retry() async {
    if (_switching || _accessError != null) return;
    setState(() {
      _switching = true;
      _error = null;
      _ready = false;
    });
    final old = _controller;
    old?.removeListener(_onPlaybackChanged);
    if (old != null) unawaited(old.dispose());
    if (!mounted) return;
    setState(() {
      _controller = null;
      _switching = false;
    });
    await _openVideo();
  }

  Future<void> _toggleCaptions(bool enabled) async {
    final controller = _controller;
    if (controller == null || !_canControl) return;
    if (!enabled) {
      _captions.value = _captions.value.copyWith(enabled: false);
      return;
    }
    setState(() {
      _loadingCaptions = true;
      _captionError = null;
    });
    final generation = _generation;
    try {
      final file = await loadCaptionFile(_subtitleSource);
      if (!mounted || generation != _generation) return;
      await controller.setClosedCaptionFile(Future.value(file));
      _captions.value = _captions.value.copyWith(enabled: true);
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _captionError =
            'No se pudieron cargar los subtítulos. Puedes volver a intentarlo.');
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loadingCaptions = false);
      }
    }
  }

  Future<void> _fullscreen() async {
    final controller = _controller;
    if (!_canControl || controller == null) return;
    _fullscreenOpen = true;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => FullscreenPlayerScreen(
                controller: controller, captions: _captions),
            fullscreenDialog: true));
    _fullscreenOpen = false;
    if (!mounted) return;
    if (_nextPending) {
      _nextPending = false;
      await _playNext();
    }
  }

  void _seekBy(Duration offset) {
    final controller = _controller!;
    final target = controller.value.position + offset;
    controller.seekTo(Duration(
        milliseconds: target.inMilliseconds
            .clamp(0, controller.value.duration.inMilliseconds)));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_saveProgress(sync: true));
      _controller?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appState.removeListener(_onAppChanged);
    unawaited(_saveProgress(sync: true));
    _generation++;
    _sleepTimer.dispose();
    _captions.dispose();
    _controller?.removeListener(_onPlaybackChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = _canControl && controller != null;
    final error = _accessError ?? _error;
    final item = _item;
    final next = item == null ? null : nextEpisode(item, _episode);
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.trailer
              ? 'Tráiler de ${widget.contentTitle}'
              : _episode?.title ?? widget.contentTitle)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        AspectRatio(
            aspectRatio: ready ? controller.value.aspectRatio : 16 / 9,
            child: error != null
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(error, textAlign: TextAlign.center),
                    if (_accessError == null && controller != null)
                      TextButton(
                          onPressed: _retry, child: const Text('Reintentar')),
                  ]))
                : ready
                    ? GestureDetector(
                        onTap: () => controller.value.isPlaying
                            ? controller.pause()
                            : controller.play(),
                        child: Stack(alignment: Alignment.center, children: [
                          VideoPlayer(controller),
                          ValueListenableBuilder<CaptionPreferences>(
                              valueListenable: _captions,
                              builder: (_, settings, __) => Positioned(
                                  bottom: 12,
                                  left: 12,
                                  right: 12,
                                  child: settings.enabled
                                      ? ClosedCaption(
                                          text: controller.value.caption.text,
                                          textStyle: TextStyle(
                                              color: Colors.white,
                                              fontSize: settings.fontSize))
                                      : const SizedBox.shrink())),
                          if (!controller.value.isPlaying)
                            const Icon(Icons.play_arrow,
                                size: 56, color: Colors.white),
                        ]))
                    : const Center(child: CircularProgressIndicator())),
        if (ready) ...[
          VideoProgressIndicator(controller, allowScrubbing: true),
          Text(
              '${formatPlaybackTime(controller.value.position)} / ${formatPlaybackTime(controller.value.duration)}'),
        ],
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          IconButton(
              tooltip: 'Retroceder 10 segundos',
              icon: const Icon(Icons.replay_10),
              onPressed:
                  ready ? () => _seekBy(const Duration(seconds: -10)) : null),
          IconButton(
              tooltip:
                  ready && controller.value.isPlaying ? 'Pausar' : 'Reproducir',
              icon: Icon(ready && controller.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow),
              onPressed: ready
                  ? () => controller.value.isPlaying
                      ? controller.pause()
                      : controller.play()
                  : null),
          IconButton(
              tooltip: 'Avanzar 10 segundos',
              icon: const Icon(Icons.forward_10),
              onPressed:
                  ready ? () => _seekBy(const Duration(seconds: 10)) : null),
          IconButton(
              tooltip: 'Silenciar',
              icon: Icon(ready && controller.value.volume == 0
                  ? Icons.volume_off
                  : Icons.volume_up),
              onPressed: ready
                  ? () =>
                      controller.setVolume(controller.value.volume == 0 ? 1 : 0)
                  : null),
          IconButton(
              tooltip: 'Pantalla completa',
              icon: const Icon(Icons.fullscreen),
              onPressed: ready ? _fullscreen : null),
        ]),
        if (!widget.trailer) ...[
          SwitchListTile(
              title: const Text(
                  'Reproducir el siguiente episodio automáticamente'),
              value: _autoplay,
              onChanged: (value) => setState(() => _autoplay = value)),
          if (next != null)
            OutlinedButton.icon(
                onPressed: ready ? _playNext : null,
                icon: const Icon(Icons.skip_next),
                label: Text('Siguiente: ${next.title}')),
          TextButton.icon(
              icon: const Icon(Icons.replay),
              label: const Text('Ver desde inicio'),
              onPressed: ready
                  ? () async {
                      await controller.seekTo(Duration.zero);
                      _completionHandled = false;
                      await _saveProgress(sync: true);
                      if (mounted && _accessError == null) {
                        await controller.play();
                      }
                    }
                  : null),
          if (_subtitleSource.isNotEmpty)
            ValueListenableBuilder<CaptionPreferences>(
                valueListenable: _captions,
                builder: (_, settings, __) => Column(children: [
                      SwitchListTile(
                          title: const Text('Subtítulos'),
                          subtitle: _loadingCaptions
                              ? const Text('Cargando subtítulos')
                              : null,
                          value: settings.enabled,
                          onChanged: ready && !_loadingCaptions
                              ? _toggleCaptions
                              : null),
                      if (settings.enabled)
                        Row(children: [
                          const Text('Tamaño del texto'),
                          Expanded(
                              child: Slider(
                                  min: 14,
                                  max: 36,
                                  divisions: 11,
                                  value: settings.fontSize,
                                  label: '${settings.fontSize.toInt()}',
                                  onChanged: (value) => _captions.value =
                                      settings.copyWith(fontSize: value)))
                        ]),
                    ])),
          if (_captionError != null)
            Text(_captionError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ValueListenableBuilder<Duration?>(
              valueListenable: _sleepTimer,
              builder: (_, duration, __) => DropdownButtonFormField<int>(
                    key: ValueKey(duration?.inMinutes ?? 0),
                    value: duration?.inMinutes ?? 0,
                    decoration: const InputDecoration(
                        labelText: 'Detener reproducción después de'),
                    items: const [
                      DropdownMenuItem(
                          value: 0, child: Text('Sin temporizador')),
                      DropdownMenuItem(value: 15, child: Text('15 minutos')),
                      DropdownMenuItem(value: 30, child: Text('30 minutos')),
                      DropdownMenuItem(value: 60, child: Text('60 minutos'))
                    ],
                    onChanged: (minutes) => _sleepTimer.schedule(
                        minutes == null || minutes == 0
                            ? null
                            : Duration(minutes: minutes)),
                  )),
          const SizedBox(height: 16),
          Row(children: [
            IconButton(
                tooltip: 'Me gusta',
                icon: Icon(appState.ratingFor(widget.contentTitle) == true
                    ? Icons.thumb_up
                    : Icons.thumb_up_outlined),
                onPressed: _accessError == null
                    ? () => appState.setContentRating(
                        widget.contentTitle,
                        appState.ratingFor(widget.contentTitle) == true
                            ? null
                            : true)
                    : null),
            IconButton(
                tooltip: 'No me gusta',
                icon: Icon(appState.ratingFor(widget.contentTitle) == false
                    ? Icons.thumb_down
                    : Icons.thumb_down_outlined),
                onPressed: _accessError == null
                    ? () => appState.setContentRating(
                        widget.contentTitle,
                        appState.ratingFor(widget.contentTitle) == false
                            ? null
                            : false)
                    : null),
            const Spacer(),
            OutlinedButton.icon(
                onPressed: _accessError == null
                    ? () => appState.toggleMyList(widget.contentTitle)
                    : null,
                icon: Icon(appState.isInMyList(widget.contentTitle)
                    ? Icons.favorite
                    : Icons.favorite_border),
                label: const Text('Mi lista')),
          ]),
        ],
      ]),
    );
  }
}
