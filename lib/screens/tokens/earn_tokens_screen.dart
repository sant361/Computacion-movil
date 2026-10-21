import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import 'games_screen.dart';

/// Req. 77, 78: ver un anuncio a cambio de tokens.
class EarnTokensScreen extends StatelessWidget {
  const EarnTokensScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ganar tokens')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFFEEF0F4), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.play_circle_outline, size: 48),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Ver anuncio y ganar tokens',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Recibe 50 tokens al completar la reproducción del anuncio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: reproducir el anuncio real antes de acreditar los tokens.
                appState.addTokens(50, reason: 'Anuncio visto');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('+50 tokens acreditados')),
                );
                Navigator.pop(context);
              },
              child: const Text('VER ANUNCIO'),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('o', style: TextStyle(color: Colors.grey))),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const GamesScreen()),
              ),
              child: const Text('Ganar tokens con juegos'),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text('Límite diario: 4 anuncios', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
