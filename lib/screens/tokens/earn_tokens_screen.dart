import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import 'games_screen.dart';

/// Req. 77, 78: ver un anuncio a cambio de tokens.
///
/// El anuncio es simulado (una cuenta regresiva de [_adSeconds] segundos).
/// Los tokens solo se acreditan si el anuncio se ve completo, y se respeta
/// el límite diario de [AppState.dailyAdLimit] anuncios por cuenta.
class EarnTokensScreen extends StatefulWidget {
  const EarnTokensScreen({super.key});

  @override
  State<EarnTokensScreen> createState() => _EarnTokensScreenState();
}

class _EarnTokensScreenState extends State<EarnTokensScreen> {
  static const _adSeconds = 5;
  static const _reward = 50;
  static const _demoAuthEnabled = bool.fromEnvironment('DEMO_AUTH_ENABLED');

  Timer? _timer;
  int _watchedToday = 0;
  int _secondsLeft = 0;
  bool _playing = false;

  String get _userId =>
      (kIsWeb && _demoAuthEnabled ? null : FirebaseAuth.instance.currentUser?.uid) ?? 'local';

  bool get _limitReached => _watchedToday >= AppState.dailyAdLimit;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadCount() async {
    final count = await appState.adsWatchedToday(_userId);
    if (mounted) setState(() => _watchedToday = count);
  }

  void _startAd() {
    if (_playing || _limitReached) return;
    setState(() {
      _playing = true;
      _secondsLeft = _adSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        _finishAd();
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _finishAd() async {
    appState.addTokens(_reward, reason: 'Anuncio visto');
    await appState.recordAdWatched(_userId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('+$_reward tokens acreditados')),
    );
    Navigator.pop(context);
  }

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
                child: _playing
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Anuncio', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('$_secondsLeft', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : const Icon(Icons.play_circle_outline, size: 48),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Ver anuncio y ganar tokens',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Recibe $_reward tokens al completar la reproducción del anuncio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_playing || _limitReached) ? null : _startAd,
              child: Text(_playing ? 'VIENDO ANUNCIO...' : 'VER ANUNCIO'),
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
              onPressed: _playing
                  ? null
                  : () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const GamesScreen()),
                      ),
              child: const Text('Ganar tokens con juegos'),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                _limitReached
                    ? 'Llegaste al límite de hoy. Vuelve mañana.'
                    : 'Límite diario: ${AppState.dailyAdLimit} anuncios ($_watchedToday vistos hoy)',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
