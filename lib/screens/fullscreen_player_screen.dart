import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Pantalla completa del reproductor: rota a horizontal, oculta la barra de
/// sistema y reutiliza el mismo [VideoPlayerController] que ya estaba
/// reproduciendo, para que el video no se reinicie al entrar o salir.
class FullscreenPlayerScreen extends StatefulWidget {
  final VideoPlayerController controller;

  const FullscreenPlayerScreen({super.key, required this.controller});

  @override
  State<FullscreenPlayerScreen> createState() => _FullscreenPlayerScreenState();
}

class _FullscreenPlayerScreenState extends State<FullscreenPlayerScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _onTick() => setState(() {});

  Future<void> _exitFullscreen() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    // Restaura orientación y barra de sistema por si se sale sin pasar por _exitFullscreen
    // (por ejemplo con el botón "atrás" físico del dispositivo).
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitFullscreen();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _exitFullscreen,
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VideoProgressIndicator(controller, allowScrubbing: true, padding: EdgeInsets.zero),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatDuration(controller.value.position),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: () => setState(
                            () => controller.value.isPlaying ? controller.pause() : controller.play(),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDuration(controller.value.duration),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
