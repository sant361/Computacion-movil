import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'fullscreen_player_screen.dart';

/// Req. 20-27, 29, 30, 34, 48: reproductor de video (Serie).
///
/// Usa el video de muestra público de Flutter para que la pantalla reproduzca
/// contenido real sin depender de un backend. Para producción, reemplaza la
/// URL de [_sampleVideoUrl] por la del video real del episodio.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  static const _sampleVideoUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

  late final VideoPlayerController _controller;
  bool _autoplay = true;
  bool _watchFromStart = true;
  bool _inMyList = false;
  bool? _liked;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(_sampleVideoUrl))
      ..addListener(() => setState(() {}))
      ..initialize().then((_) {
        setState(() {});
        if (_autoplay) _controller.play();
      });
  }

  @override
  void dispose() {
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
    setState(() => _controller.setVolume(_controller.value.volume == 0 ? 1 : 0));
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
      appBar: AppBar(title: const Text('Serie')),
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
                            child: const Icon(Icons.play_arrow, size: 56, color: Colors.white),
                          ),
                      ],
                    )
                  : Container(
                      decoration:
                          BoxDecoration(color: const Color(0xFFEEF0F4), borderRadius: BorderRadius.circular(10)),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          if (isReady) ...[
            VideoProgressIndicator(_controller, allowScrubbing: true, padding: EdgeInsets.zero),
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
                onPressed: isReady ? () => _seekBy(const Duration(seconds: -10)) : null,
              ),
              IconButton(
                icon: Icon(isReady && _controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: isReady ? _togglePlayPause : null,
              ),
              IconButton(
                icon: const Icon(Icons.forward_10),
                onPressed: isReady ? () => _seekBy(const Duration(seconds: 10)) : null,
              ),
              IconButton(
                icon: Icon(isReady && _controller.value.volume == 0 ? Icons.volume_off : Icons.volume_up),
                onPressed: isReady ? _toggleMute : null,
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen),
                onPressed: isReady
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullscreenPlayerScreen(controller: _controller),
                            fullscreenDialog: true,
                          ),
                        )
                    : null,
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: const [
              Chip(label: Text('CC')), // subtítulos — req. 29
              Chip(label: Text('Audio')), // idioma de audio — req. 30
              Chip(label: Text('Calidad')), // calidad de video — req. 26
            ],
          ),
          SwitchListTile(
            value: _autoplay,
            onChanged: (v) => setState(() => _autoplay = v),
            title: const Text('Autoplay'), // req. 27
          ),
          OutlinedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reproduciendo siguiente episodio (demo)')),
            ),
            child: const Text('Siguiente episodio ▶'),
          ),
          const SizedBox(height: 16),
          const Text('Serie · Temporada 1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: Icon(_liked == true ? Icons.thumb_up : Icons.thumb_up_outlined),
                onPressed: () => setState(() => _liked = _liked == true ? null : true),
              ), // req. 31 calificación
              IconButton(
                icon: Icon(_liked == false ? Icons.thumb_down : Icons.thumb_down_outlined),
                onPressed: () => setState(() => _liked = _liked == false ? null : false),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _inMyList = !_inMyList);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_inMyList ? 'Agregado a Mi lista' : 'Quitado de Mi lista')),
                  );
                }, // req. 34 mi lista
                icon: Icon(_inMyList ? Icons.favorite : Icons.favorite_border, size: 18),
                label: const Text('Lista'),
              ),
            ],
          ),
          RadioListTile(
            value: true,
            groupValue: _watchFromStart,
            onChanged: (v) => setState(() => _watchFromStart = v ?? true),
            title: const Text('Ver desde inicio'),
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
