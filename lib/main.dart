import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // firebase_options.dart lo genera "flutterfire configure" automáticamente
  // con los datos de TU proyecto de Firebase; no se edita a mano.
  if (!kIsWeb || !const bool.fromEnvironment('DEMO_AUTH_ENABLED')) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  runApp(const StreamingApp());
}

class StreamingApp extends StatelessWidget {
  const StreamingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '+Wnovelas',
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

  Future<void> _startup() async {
    await appState.load();
    if (appState.isLoggedIn) {
      await appState.loadCatalogFromFirestore();
      await appState.loadProfiles(FirebaseAuth.instance.currentUser?.uid ?? 'local');
      await appState.loadParentalSettings(FirebaseAuth.instance.currentUser?.uid ?? 'local');
      await appState.loadAdminStatus(FirebaseAuth.instance.currentUser?.uid ?? 'local');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startup(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return appState.isLoggedIn ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
