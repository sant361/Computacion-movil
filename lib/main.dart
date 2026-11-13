import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_text.dart';
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
  runApp(const StreamingApp());
}

class StreamingApp extends StatelessWidget {
  const StreamingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: appState,
        builder: (context, _) => MaterialApp(
              title: '+Wnovelas',
              locale: Locale(appState.languageCode),
              supportedLocales: const [
                Locale('es'),
                Locale('en'),
                Locale('fr')
              ],
              localizationsDelegates: const [
                AppStrings.delegate,
                ...GlobalMaterialLocalizations.delegates
              ],
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorSchemeSeed: const Color(0xFF3D5A80),
                useMaterial3: true,
              ),
              home: const AppStartup(),
            ));
  }
}

/// Carga el estado guardado (tokens, Mi lista) antes de mostrar el Login,
/// para que la app abra ya con los datos reales del dispositivo.
class AppStartup extends StatefulWidget {
  const AppStartup({super.key, this.initialize, this.readyBuilder});
  final Future<void> Function()? initialize;
  final WidgetBuilder? readyBuilder;

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  late Future<void> _pending;

  @override
  void initState() {
    super.initState();
    _pending = _start();
  }

  Future<void> _start() => Future<void>.sync(widget.initialize ?? _startup);

  Future<void> _startup() async {
    if ((!kIsWeb || !const bool.fromEnvironment('DEMO_AUTH_ENABLED')) &&
        Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
    await appState.load();
    if (appState.isLoggedIn) {
      await appState.loadCatalogFromFirestore();
      await appState.loadProfiles(Firebase.apps.isEmpty
          ? 'local'
          : FirebaseAuth.instance.currentUser?.uid ?? 'local');
      await appState.loadParentalSettings(Firebase.apps.isEmpty
          ? 'local'
          : FirebaseAuth.instance.currentUser?.uid ?? 'local');
      await appState.loadAdminStatus(Firebase.apps.isEmpty
          ? 'local'
          : FirebaseAuth.instance.currentUser?.uid ?? 'local');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _pending,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
                child: Center(
                    child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.cloud_off_outlined, size: 48),
                const SizedBox(height: 16),
                const AppText('No pudimos iniciar la aplicación',
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const AppText('Comprueba tu conexión y vuelve a intentarlo.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                    onPressed: () => setState(() {
                          _pending = _start();
                        }),
                    icon: const Icon(Icons.refresh),
                    label: const AppText('Reintentar')),
              ]),
            ))),
          );
        }
        if (widget.readyBuilder != null) return widget.readyBuilder!(context);
        return appState.isLoggedIn ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
