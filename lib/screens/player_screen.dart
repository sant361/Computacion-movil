import 'package:flutter/material.dart';

/// Req. 20-27, 29, 30, 34, 48: reproductor de video (Serie).
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _autoplay = true;
  bool _watchFromStart = true;
  bool _inMyList = false;
  bool? _liked;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Serie')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFFEEF0F4), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.play_arrow, size: 48),
            ),
          ),
          const SizedBox(height: 8),
          const LinearProgressIndicator(value: 0.3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(icon: const Icon(Icons.skip_previous), onPressed: () {}),
              IconButton(icon: const Icon(Icons.pause), onPressed: () {}),
              IconButton(icon: const Icon(Icons.skip_next), onPressed: () {}),
              IconButton(icon: const Icon(Icons.volume_up), onPressed: () {}),
              IconButton(icon: const Icon(Icons.fullscreen), onPressed: () {}),
            ],
          ),
          Wrap(
            spacing: 8,
            children: const [
              Chip(label: Text('CC')),       // subtítulos — req. 29
              Chip(label: Text('Audio')),    // idioma de audio — req. 30
              Chip(label: Text('Calidad')),  // calidad de video — req. 26
            ],
          ),
          SwitchListTile(
            value: _autoplay,
            onChanged: (v) => setState(() => _autoplay = v),
            title: const Text('Autoplay'), // req. 27
          ),
          OutlinedButton(onPressed: () {}, child: const Text('Siguiente episodio ▶')),
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
