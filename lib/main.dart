import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';

void main() => runApp(const StreamingApp());

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
      // TODO: una vez tengas el login real, navega a HomeScreen tras autenticar.
      home: const LoginScreen(),
    );
  }
}
