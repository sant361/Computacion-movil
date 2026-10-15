import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import 'tokens_screen.dart';

/// Req. 79, 80: resultado tras jugar un minijuego y tokens ganados.
class GameResultScreen extends StatefulWidget {
  final String gameName;
  final int tokensEarned;

  const GameResultScreen({super.key, required this.gameName, required this.tokensEarned});

  @override
  State<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen> {
  @override
  void initState() {
    super.initState();
    // Se acreditan los tokens una sola vez, al entrar a la pantalla de resultado.
    appState.addTokens(widget.tokensEarned, reason: 'Juego · ${widget.gameName}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Icon(Icons.star, size: 56, color: Color(0xFFEBC86E)),
              const SizedBox(height: 16),
              const Text('¡Buen trabajo!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Completaste ${widget.gameName}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _resultRow('Aciertos', '8 / 10'),
                      const Divider(),
                      _resultRow('Tiempo', '01:42'),
                      const Divider(),
                      _resultRow('Tokens ganados', '+${widget.tokensEarned}'),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const TokensScreen()),
                ),
                child: const Text('Ver historial'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('JUGAR OTRA VEZ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
