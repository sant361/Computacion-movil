import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'fullscreen_player_screen.dart';
import '../state/app_state.dart';

/// Req. 20-27, 29, 30, 34, 48: reproductor de video (Serie).
///
/// Usa el video de muestra público de Flutter para que la pantalla reproduzca
/// contenido real sin depender de un backend. Para producción, reemplaza la
/// URL de [_sampleVideoUrl] por la del video real del episodio.
class PlayerScreen extends StatefulWidget {
  final String contentTitle;
  const PlayerScreen({super.key, this.contentTitle = 'Serie · Temporada 1'});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  static const _sampleVideoUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

  late final VideoPlayerController _controller;
  bool _autoplay = true;
  late final String _playbackScope;
  bool _restored = false;
  int _lastSavedSecond = -1;

  bool? _liked;
  String _subtitles = 'Desactivados';
  String _audioLang = 'Español';
  String _quality = 'Auto';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _playbackScope = appState.playbackScope;
    final saved = appState.watchProgress(widget.contentTitle);
    _controller = VideoPlayerController.networkUrl(Uri.parse(_sampleVideoUrl));
    _controller.addListener(_onPlaybackChanged);
    _initialize(saved);
  }

  Future<void> _initialize(WatchProgress? saved) async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      if (saved != null &&
          saved.positionMs < _controller.value.duration.inMilliseconds) {
        await _controller.seekTo(Duration(milliseconds: saved.positionMs));
      }
      if (!mounted) return;
      _restored = true;
      setState(() {});
      if (_autoplay) await _controller.play();
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  void _onPlaybackChanged() {
    if (!mounted) return;
    setState(() {});
    final second = _controller.value.position.inSeconds;
    if (_restored && second != _lastSavedSecond) {
      _lastSavedSecond = second;
      unawaited(_saveProgress());
    }
  }

  Future<void> _saveProgress() async {
    if (!_restored || !_controller.value.isInitialized) return;
    try {
      await appState.saveWatchProgress(
        widget.contentTitle,
        _controller.value.position,
        _controller.value.duration,
        scope: _playbackScope,
      );
    } catch (_) {
      // La reproducción puede continuar si falla el almacenamiento local.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_saveProgress());
      _controller.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_saveProgress());
    _controller.removeListener(_onPlaybackChanged);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _seekBy(Duration offset) {
    final target = _controller.value.position + offset;
    _controller.seekTo(target);
  }

  void _toggleMute() {
    setState(
        () => _controller.setVolume(_controller.value.volume == 0 ? 1 : 0));
  }

  Future<void> _pickOption({
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ...options.map(
              (o) => RadioListTile(
                value: o,
                groupValue: current,
                title: Text(o),
                onChanged: (v) => Navigator.pop(context, v),
              ),
            ),
          ],
        ),
      ),
    );
    if (choice != null) onSelected(choice);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _controller.value.isInitialized;

    return Scaffold(
      appBar: AppBar(title: Text(widget.contentTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: isReady ? _togglePlayPause : null,
            child: AspectRatio(
              aspectRatio: isReady ? _controller.value.aspectRatio : 16 / 9,
              child: isReady
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_controller),
                        if (!_controller.value.isPlaying)
                          Container(
                            color: Colors.black26,
                            child: const Icon(Icons.play_arrow,
                                size: 56, color: Colors.white),
                          ),
                      ],
                    )
                  : Container(
                      decoration: BoxDecoration(
                          color: const Color(0xFFEEF0F4),
                          borderRadius: BorderRadius.circular(10)),
                      child: Center(
                          child: _controller.value.hasError
                              ? const Text('No se pudo cargar el video.')
                              : const CircularProgressIndicator()),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          if (isReady) ...[
            VideoProgressIndicator(_controller,
                allowScrubbing: true, padding: EdgeInsets.zero),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ] else
            const LinearProgressIndicator(value: 0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: isReady
                    ? () => _seekBy(const Duration(seconds: -10))
                    : null,
              ),
              IconButton(
                icon: Icon(isReady && _controller.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow),
                onPressed: isReady ? _togglePlayPause : null,
              ),
              IconButton(
                icon: const Icon(Icons.forward_10),
                onPressed:
                    isReady ? () => _seekBy(const Duration(seconds: 10)) : null,
              ),
              IconButton(
                icon: Icon(isReady && _controller.value.volume == 0
                    ? Icons.volume_off
                    : Icons.volume_up),
                onPressed: isReady ? _toggleMute : null,
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen),
                onPressed: isReady
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FullscreenPlayerScreen(controller: _controller),
                            fullscreenDialog: true,
                          ),
                        )
                    : null,
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: Text('CC: $_subtitles'), // req. 29 subtítulos
                onPressed: () => _pickOption(
                  title: 'Subtítulos',
                  options: const [
                    'Desactivados',
                    'Español',
                    'Inglés',
                    'Portugués'
                  ],
                  current: _subtitles,
                  onSelected: (v) => setState(() => _subtitles = v),
                ),
              ),
              ActionChip(
                label: Text('Audio: $_audioLang'), // req. 30 idioma de audio
                onPressed: () => _pickOption(
                  title: 'Idioma de audio',
                  options: const ['Español', 'Inglés', 'Portugués'],
                  current: _audioLang,
                  onSelected: (v) => setState(() => _audioLang = v),
                ),
              ),
              ActionChip(
                label: Text('Calidad: $_quality'), // req. 26 calidad de video
                onPressed: () => _pickOption(
                  title: 'Calidad de video',
                  options: const ['Auto', '480p', '720p', '1080p'],
                  current: _quality,
                  onSelected: (v) => setState(() => _quality = v),
                ),
              ),
            ],
          ),
          SwitchListTile(
            value: _autoplay,
            onChanged: (v) => setState(() => _autoplay = v),
            title: const Text('Autoplay'), // req. 27
          ),
          OutlinedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Reproduciendo siguiente episodio (demo)')),
            ),
            child: const Text('Siguiente episodio ▶'),
          ),
          const SizedBox(height: 16),
          Text(widget.contentTitle,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: Icon(
                    _liked == true ? Icons.thumb_up : Icons.thumb_up_outlined),
                onPressed: () =>
                    setState(() => _liked = _liked == true ? null : true),
              ), // req. 31 calificación
              IconButton(
                icon: Icon(_liked == false
                    ? Icons.thumb_down
                    : Icons.thumb_down_outlined),
                onPressed: () =>
                    setState(() => _liked = _liked == false ? null : false),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {
                  appState.toggleMyList(widget.contentTitle);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        appState.isInMyList(widget.contentTitle)
                            ? 'Agregado a Mi lista'
                            : 'Quitado de Mi lista',
                      ),
                    ),
                  );
                }, // req. 34 mi lista
                icon: Icon(
                    appState.isInMyList(widget.contentTitle)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 18),
                label: const Text('Lista'),
              ),
            ],
          ),
          TextButton.icon(
            icon: const Icon(Icons.replay),
            label: const Text('Ver desde inicio'),
            onPressed: isReady && _restored
                ? () async {
                    await _controller.seekTo(Duration.zero);
                    await _saveProgress();
                    if (mounted) await _controller.play();
                  }
                : null,
          ),
          CheckboxListTile(
            value: false,
            onChanged: (_) {},
            title: const Text('Episodios'),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enlace copiado para compartir')),
              ), // req. 48 compartir
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Compartir'),
            ),
          ),
        ],
      ),
    );
  }
}
