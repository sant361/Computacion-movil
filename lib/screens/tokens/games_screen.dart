import 'package:flutter/material.dart';
import 'game_result_screen.dart';

/// Req. 79: catálogo de minijuegos para ganar tokens.
class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  static const games = [
    {'nombre': 'Trivia de series', 'rango': '+30 a +80', 'tokens': 80},
    {'nombre': 'Memoria', 'rango': '+20 a +60', 'tokens': 60},
    {'nombre': 'Rompecabezas', 'rango': '+40 a +100', 'tokens': 100},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elige un juego')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...games.map(
            (g) => Card(
              child: ListTile(
                leading: const Icon(Icons.videogame_asset_outlined),
                title: Text(g['nombre'] as String),
                subtitle: Text('Tokens: ${g['rango']}'),
                trailing: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameResultScreen(
                        gameName: g['nombre'] as String,
                        tokensEarned: g['tokens'] as int,
                      ),
                    ),
                  ),
                  child: const Text('Jugar'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('Disponible en todos los dispositivos', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
