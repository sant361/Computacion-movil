import 'package:flutter/material.dart';
import 'unlock_confirm_screen.dart';
import 'earn_tokens_screen.dart';
import '../payments/plans_screen.dart';

/// Req. 84, 87, 88: alternativas de acceso cuando un capítulo está restringido.
class AccessOptionsScreen extends StatelessWidget {
  const AccessOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capítulo restringido')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Elige cómo quieres continuar', textAlign: TextAlign.center),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: const Text('Desbloquear con tokens', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('120 tokens'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UnlockConfirmScreen()),
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Obtener tokens', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Ver anuncio o jugar'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EarnTokensScreen()),
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Contratar un plan', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Acceso ilimitado'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlansScreen()),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No tienes suficientes tokens para este capítulo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
