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
  bool _saving = false;
  String? _error;
  Future<void> Function()? _retry;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'local';
      await appState.loadProfiles(uid);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar los perfiles.';
          _retry = _load;
        });
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save(Future<void> Function() action) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo guardar el cambio.';
          _retry = () => _save(action);
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectProfile(String name) async {
    await _save(() async {
      await appState.setActiveProfile(name);
      if (mounted) Navigator.pop(context, name);
    });
  }

  Future<void> _addProfile() async {
    var input = '';
    final form = GlobalKey<FormState>();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo perfil'),
        content: Form(
          key: form,
          child: TextFormField(
            onChanged: (value) => input = value,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nombre'),
            validator: (value) {
              final name = value?.trim() ?? '';
              if (name.isEmpty) return 'Escribe un nombre.';
              if (appState.profiles.any(
                (p) => p.trim().toLowerCase() == name.toLowerCase(),
              )) {
                return 'Este nombre ya existe.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, input.trim());
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (name != null && name.trim().isNotEmpty) {
      await _save(() => appState.addProfile(name));
    }
  }

  Future<void> _removeProfile(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar este perfil?'),
        content: Text('Se eliminará "$name" de esta cuenta.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) {
      await _save(() => appState.removeProfile(name));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF07111F),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFC093F),
            semanticsLabel: 'Cargando perfiles',
          ),
        ),
      );
    }
    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF07111F),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF07111F),
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFC093F),
          brightness: Brightness.dark,
        ),
      ),
      child: PopScope(
        canPop: !_saving,
        child: Scaffold(
          appBar: AppBar(title: const Text('¿Quién ve ahora?')),
          body: ListenableBuilder(
            listenable: appState,
            builder: (context, _) {
              final profiles = appState.profiles;
              final active = appState.activeProfile;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    if (_saving)
                      const LinearProgressIndicator(
                        semanticsLabel: 'Guardando cambios',
                      ),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                      TextButton(
                        onPressed: _saving ? null : _retry,
                        child: const Text('Reintentar'),
                      ),
                    ],
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisExtent: 210,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      children: [
                        ...profiles.map(
                          (name) => _ProfileAvatar(
                            name: name,
                            selected: active == name,
                            showDelete: _editMode,
                            onTap: _saving || _error != null || _editMode
                                ? null
                                : () => _selectProfile(name),
                            onDelete: _saving || _error != null
                                ? null
                                : () => _removeProfile(name),
                          ),
                        ),
                        _ProfileAvatar(
                          name: 'Agregar',
                          isAdd: true,
                          onTap: _saving || _error != null ? null : _addProfile,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: _saving || _error != null
                          ? null
                          : () => setState(() => _editMode = !_editMode),
                      child: Text(_editMode ? 'Listo' : 'Gestionar perfiles'),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Cada perfil guarda su propio historial',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String name;
  final bool selected;
  final bool isAdd;
  final bool showDelete;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _ProfileAvatar({
    required this.name,
    required this.onTap,
    this.onDelete,
    this.selected = false,
    this.isAdd = false,
    this.showDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    const palette = [
      Color(0xFF2956A3),
      Color(0xFF763DA1),
      Color(0xFF00695C),
      Color(0xFFAD3256),
    ];
    var hash = 0;
    for (final rune in name.trim().toLowerCase().runes) {
      hash = (hash * 31 + rune) % 1000000007;
    }
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final initials = words.isEmpty
        ? '?'
        : [
            words.first,
            if (words.length > 1) words.last,
          ].map((w) => w.characters.first).join().toUpperCase();
    return Column(
      children: [
        Expanded(
          child: Semantics(
            selected: selected,
            child: Material(
              color: const Color(0xFF132237),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: selected ? const Color(0xFFFC093F) : Colors.white24,
                  width: selected ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: SizedBox.expand(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: isAdd
                                ? const Color(0xFF26364B)
                                : palette[hash % palette.length],
                            child: isAdd
                                ? const Icon(
                                    Icons.add,
                                    size: 32,
                                    color: Colors.white,
                                  )
                                : Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                    ),
                                  ),
                          ),
                          if (selected && !isAdd)
                            const Positioned(
                              right: -2,
                              bottom: -2,
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.green,
                                child: Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (selected && !isAdd)
                        const Text(
                          'Perfil activo',
                          style: TextStyle(color: Colors.greenAccent),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showDelete && !isAdd)
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar'),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
          ),
      ],
    );
  }
}
