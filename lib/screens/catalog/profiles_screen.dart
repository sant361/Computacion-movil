import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../state/app_state.dart';

/// Req. 40: selección y gestión de perfiles, guardados por cuenta.
class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  bool _editMode = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'local';
    await appState.loadProfiles(uid);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _selectProfile(String name) async {
    await appState.setActiveProfile(name);
    if (!mounted) return;
    Navigator.pop(context, name);
  }

  Future<void> _addProfile() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo perfil'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await appState.addProfile(name);
    }
  }

  Future<void> _removeProfile(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar este perfil?'),
        content: Text('Se eliminará "$name" de esta cuenta.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await appState.removeProfile(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('¿Quién ve ahora?')),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final profiles = appState.profiles;
          final active = appState.activeProfile;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    ...profiles.map(
                      (name) => _ProfileAvatar(
                        name: name,
                        selected: active == name,
                        showDelete: _editMode,
                        onTap: () => _editMode ? _removeProfile(name) : _selectProfile(name),
                      ),
                    ),
                    _ProfileAvatar(
                      name: 'Agregar',
                      isAdd: true,
                      onTap: _addProfile,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => setState(() => _editMode = !_editMode),
                  child: Text(_editMode ? 'Listo' : 'Editar perfiles'),
                ),
                const Spacer(),
                const Text(
                  'Cada perfil guarda su propio historial',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String name;
  final bool selected;
  final bool isAdd;
  final bool showDelete;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.name,
    required this.onTap,
    this.selected = false,
    this.isAdd = false,
    this.showDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: isAdd ? const Color(0xFFEEF0F4) : const Color(0xFFC8CBD0),
                child: Icon(
                  isAdd ? Icons.add : (showDelete ? Icons.delete_outline : Icons.person),
                  size: 32,
                  color: isAdd ? Colors.grey.shade600 : Colors.white,
                ),
              ),
              if (selected && !isAdd)
                const Positioned(
                  right: -2,
                  bottom: -2,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(name, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
