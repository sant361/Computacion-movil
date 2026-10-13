import 'package:flutter/material.dart';

/// Req. 7: doble autenticación (2FA) y cambio de contraseña.
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _twoFactorEnabled = true;
  String _method = 'app';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.shield_outlined),
              value: _twoFactorEnabled,
              onChanged: (v) => setState(() => _twoFactorEnabled = v),
              title: const Text('Doble autenticación'),
              subtitle: const Text('Verificación adicional al iniciar sesión'),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Método', style: TextStyle(fontWeight: FontWeight.bold)),
          RadioListTile(
            value: 'app',
            groupValue: _method,
            onChanged: _twoFactorEnabled ? (v) => setState(() => _method = v as String) : null,
            title: const Text('App autenticadora'),
          ),
          RadioListTile(
            value: 'sms',
            groupValue: _method,
            onChanged: _twoFactorEnabled ? (v) => setState(() => _method = v as String) : null,
            title: const Text('SMS al número guardado'),
          ),
          const Divider(),
          const Text('Contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              // TODO: abrir formulario de cambio de contraseña.
            },
            child: const Text('Cambiar contraseña'),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text('Recomendamos activar 2FA', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
