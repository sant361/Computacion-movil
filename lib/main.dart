import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'state/app_state.dart';

void main() {
  // Asegura que los plugins (como shared_preferences) estén listos antes de usarlos.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StreamingApp());
}

class StreamingApp extends StatelessWidget {
  const StreamingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Streaming App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3D5A80),
        useMaterial3: true,
      ),
      home: const _AppStartup(),
    );
  }
}

/// Carga el estado guardado (tokens, Mi lista) antes de mostrar el Login,
/// para que la app abra ya con los datos reales del dispositivo.
class _AppStartup extends StatelessWidget {
  const _AppStartup();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: appState.load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return appState.isLoggedIn ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
