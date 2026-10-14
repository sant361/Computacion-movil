import 'package:flutter/material.dart';

/// Req. 82, 83: confirmar el desbloqueo de un capítulo con tokens.
class UnlockConfirmScreen extends StatelessWidget {
  final String chapterName;
  final int cost;
  final int currentBalance;

  const UnlockConfirmScreen({
    super.key,
    this.chapterName = 'Capítulo 13',
    this.cost = 120,
    this.currentBalance = 1250,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = currentBalance - cost;
    final canAfford = remaining >= 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Desbloquear capítulo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: const Color(0xFFEEF0F4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(chapterName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Costo: $cost tokens'),
                    Text('Saldo actual: $currentBalance', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              canAfford
                  ? 'Saldo después del desbloqueo: $remaining tokens'
                  : 'No tienes saldo suficiente para este capítulo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: canAfford ? Colors.black : Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canAfford
                        ? () {
                            // TODO: descontar tokens en el backend y desbloquear el capítulo.
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Capítulo desbloqueado')),
                            );
                            Navigator.pop(context);
                          }
                        : null,
                    child: const Text('DESBLOQUEAR'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
