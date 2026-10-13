import 'package:flutter/material.dart';

/// Req. 40: selección y gestión de perfiles.
class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  final List<String> _profiles = ['Ana', 'Luis', 'Kids'];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('¿Quién ve ahora?')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                ..._profiles.asMap().entries.map(
                      (e) => _ProfileAvatar(
                        name: e.value,
                        selected: _selected == e.key,
                        onTap: () {
                          setState(() => _selected = e.key);
                          Navigator.pop(context, e.value);
                        },
                      ),
                    ),
                _ProfileAvatar(
                  name: 'Agregar',
                  isAdd: true,
                  onTap: () {
                    // TODO: abrir formulario para crear un nuevo perfil.
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                // TODO: pantalla de edición de perfiles (renombrar, borrar, marcar infantil).
              },
              child: const Text('Editar perfiles'),
            ),
            const Spacer(),
            const Text(
              'Cada perfil guarda su propio historial',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String name;
  final bool selected;
  final bool isAdd;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.name,
    required this.onTap,
    this.selected = false,
    this.isAdd = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: isAdd ? const Color(0xFFEEF0F4) : const Color(0xFFC8CBD0),
            child: Icon(
              isAdd ? Icons.add : Icons.person,
              size: 32,
              color: isAdd ? Colors.grey.shade600 : Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(name, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
