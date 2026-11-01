import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../playback/playback_support.dart';

class FullscreenPlayerScreen extends StatefulWidget {
  const FullscreenPlayerScreen({super.key, required this.controller});
  final VideoPlayerController controller;
  @override
  State<FullscreenPlayerScreen> createState() => _FullscreenPlayerScreenState();
}

class _FullscreenPlayerScreenState extends State<FullscreenPlayerScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _exitFullscreen() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
          child: Stack(alignment: Alignment.center, children: [
        Center(
            child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller))),
        Positioned(
            top: 8,
            left: 8,
            child: IconButton(
                tooltip: 'Salir de pantalla completa',
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _exitFullscreen)),
        Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              VideoProgressIndicator(controller,
                  allowScrubbing: true, padding: EdgeInsets.zero),
              Row(children: [
                Text(formatPlaybackTime(controller.value.position),
                    style: const TextStyle(color: Colors.white)),
                const Spacer(),
                IconButton(
                    tooltip:
                        controller.value.isPlaying ? 'Pausar' : 'Reproducir',
                    icon: Icon(
                        controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white),
                    onPressed: () => controller.value.isPlaying
                        ? controller.pause()
                        : controller.play()),
                const Spacer(),
                Text(formatPlaybackTime(controller.value.duration),
                    style: const TextStyle(color: Colors.white)),
              ]),
            ])),
      ])),
    );
  }
}
