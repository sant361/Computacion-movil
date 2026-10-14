import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Req. 25: reproducción en pantalla completa, en horizontal.
///
/// Reutiliza el mismo [VideoPlayerController] que ya estaba reproduciendo en
/// PlayerScreen, así que el video continúa exactamente donde iba, sin cortes.
class FullscreenPlayerScreen extends StatefulWidget {
  final VideoPlayerController controller;

  const FullscreenPlayerScreen({super.key, required this.controller});

  @override
  State<FullscreenPlayerScreen> createState() => _FullscreenPlayerScreenState();
}

class _FullscreenPlayerScreenState extends State<FullscreenPlayerScreen> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _togglePlayPause() {
    setState(() {
      widget.controller.value.isPlaying ? widget.controller.pause() : widget.controller.play();
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _exitFullscreen() async {
    // Restaura la orientación/UI antes de salir, para que PlayerScreen vuelva a verse normal.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitFullscreen();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: c.value.isInitialized ? c.value.aspectRatio : 16 / 9,
                  child: VideoPlayer(c),
                ),
              ),
              if (_showControls) ...[
                Positioned(
                  top: 8,
                  left: 8,
                  child: SafeArea(
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 28),
                      onPressed: _exitFullscreen,
                    ),
                  ),
                ),
                Center(
                  child: IconButton(
                    iconSize: 56,
                    icon: Icon(
                      c.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.white,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VideoProgressIndicator(c, allowScrubbing: true, padding: EdgeInsets.zero),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(c.value.position),
                                style: const TextStyle(color: Colors.white, fontSize: 12)),
                            Text(_formatDuration(c.value.duration),
                                style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
