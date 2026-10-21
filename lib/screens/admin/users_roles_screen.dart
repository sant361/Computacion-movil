import 'package:flutter/material.dart';

/// Req. 54, 55: gestión de usuarios, roles y auditoría.
class UsersRolesScreen extends StatelessWidget {
  const UsersRolesScreen({super.key});

  static const users = [
    {'nombre': 'Ana Torres', 'correo': 'ana@mail.com', 'estado': 'Activo', 'activo': true},
    {'nombre': 'Luis Vera', 'correo': 'luis@mail.com', 'estado': 'Bloqueado', 'activo': false},
  ];

  static const roles = ['Administrador', 'Editor de contenido', 'Soporte'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Buscar usuario',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          ...users.map(
            (u) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(u['nombre'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(u['correo'] as String),
              trailing: Chip(
                label: Text(u['estado'] as String),
                backgroundColor:
                    (u['activo'] as bool)
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                labelStyle: TextStyle(color: (u['activo'] as bool) ? Colors.green : Colors.red),
              ),
            ),
          ),
          const Divider(height: 32),
          const Text('Roles y permisos', style: TextStyle(fontWeight: FontWeight.bold)),
          ...roles.map(
            (r) => ListTile(
              title: Text(r),
              trailing: TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Editar permisos del rol (demo)'))), child: const Text('Editar')),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Formulario de nuevo rol (demo)'))), child: const Text('+ Crear rol')),
          const SizedBox(height: 24),
          OutlinedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abriendo registro de auditoría (demo)'))), child: const Text('Registro de auditoría')),
        ],
      ),
    );
  }
}
