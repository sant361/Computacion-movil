import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import 'earn_tokens_screen.dart';
import 'games_screen.dart';

/// Req. 74, 75: saldo de tokens e historial (conectado a AppState).
class TokensScreen extends StatelessWidget {
  const TokensScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis tokens')),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: const Color(0xFFF7F3E9),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEBC86E),
                  child: Text('T', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                title: const Text('Saldo disponible', style: TextStyle(color: Colors.grey)),
                subtitle: Text('${appState.tokenBalance} tokens',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EarnTokensScreen())),
              child: const Text('Ver anuncio y ganar tokens'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesScreen())),
              child: const Text('Ganar tokens con juegos'),
            ),
            const Divider(height: 32),
            const Text('Historial reciente', style: TextStyle(fontWeight: FontWeight.bold)),
            ...appState.tokenHistory.map(
              (h) => ListTile(
                title: Text(h['titulo']!),
                trailing: Text(
                  h['valor']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: h['valor']!.startsWith('+') ? Colors.green : Colors.red,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
