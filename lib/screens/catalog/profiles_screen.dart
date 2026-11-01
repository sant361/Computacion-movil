import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import '../../data/catalog_item.dart';
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
      final uid = Firebase.apps.isEmpty
          ? 'local'
          : FirebaseAuth.instance.currentUser?.uid ?? 'local';
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
    final details = appState.profileDetails(name);
    final fromChild =
        appState.profileDetails(appState.activeProfile ?? '').isChild;
    if (fromChild && !details.isChild && !details.hasPin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Un adulto debe proteger este perfil con un PIN antes de usarlo desde un perfil infantil.')));
      return;
    }
    if (details.isChild &&
        !appState.profiles.any((profile) {
          final adult = appState.profileDetails(profile);
          return !adult.isChild && adult.hasPin;
        })) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Configura primero un PIN en un perfil adulto para poder volver a él.')));
      return;
    }
    final pin = details.hasPin ? await _requestPin(name) : '';
    if (pin == null || !mounted) return;
    await _save(() async {
      await appState.setActiveProfile(name, pin: pin);
      if (mounted) Navigator.pop(context, name);
    });
  }

  Future<String?> _requestPin(String name) async {
    var pin = '';
    var waiting = false;
    String? error;
    return showDialog<String>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
              builder: (context, update) => AlertDialog(
                title: Text('PIN de $name'),
                content: TextField(
                  autofocus: true,
                  obscureText: true,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) => pin = value,
                  decoration: InputDecoration(
                      labelText: 'PIN de 4 a 6 dígitos', errorText: error),
                ),
                actions: [
                  TextButton(
                      onPressed:
                          waiting ? null : () => Navigator.pop(dialogContext),
                      child: const Text('Cancelar')),
                  TextButton(
                      onPressed: waiting
                          ? null
                          : () async {
                              update(() => waiting = true);
                              final valid =
                                  await appState.verifyProfilePin(name, pin);
                              if (!dialogContext.mounted) return;
                              if (valid) {
                                Navigator.pop(dialogContext, pin);
                              } else {
                                update(() {
                                  waiting = false;
                                  error = 'El PIN no es correcto.';
                                });
                              }
                            },
                      child: Text(waiting ? 'Comprobando...' : 'Continuar')),
                ],
              ),
            ));
  }

  Future<void> _editProfile(String name) async {
    final details = appState.profileDetails(name);
    if (details.hasPin && await _requestPin(name) == null) return;
    if (!mounted) return;
    var avatar =
        _avatarIcons.containsKey(details.avatar) ? details.avatar : 'person';
    final avatarUrl = TextEditingController(
        text: details.avatar.startsWith('https://') ? details.avatar : '');
    var child = details.isChild;
    var rating = details.maxRating;
    var pin = '';
    var removePin = false;
    String? setupError;
    final form = GlobalKey<FormState>();
    final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
              builder: (context, update) => AlertDialog(
                title: Text('Editar $name'),
                content: SingleChildScrollView(
                    child: Form(
                        key: form,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          if (setupError != null)
                            Text(setupError!,
                                style:
                                    const TextStyle(color: Colors.redAccent)),
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Avatar')),
                          Wrap(
                              spacing: 8,
                              children: _avatarIcons.entries
                                  .map((entry) => ChoiceChip(
                                        label: Icon(entry.value),
                                        selected: avatar == entry.key,
                                        tooltip: _avatarNames[entry.key],
                                        onSelected: (_) => update(() {
                                          avatar = entry.key;
                                          avatarUrl.clear();
                                        }),
                                      ))
                                  .toList()),
                          TextFormField(
                            controller: avatarUrl,
                            decoration: const InputDecoration(
                                labelText:
                                    'URL de imagen del avatar (opcional)'),
                            keyboardType: TextInputType.url,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }
                              final uri = Uri.tryParse(value.trim());
                              return uri != null &&
                                      uri.scheme == 'https' &&
                                      uri.host.isNotEmpty
                                  ? null
                                  : 'Usa una dirección HTTPS válida.';
                            },
                          ),
                          SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Perfil infantil'),
                              value: child,
                              onChanged: (value) => update(() {
                                    child = value;
                                    if (child) rating = 'TP';
                                  })),
                          DropdownButtonFormField<String>(
                            value: parentalRatings.contains(rating)
                                ? rating
                                : 'TP',
                            decoration: const InputDecoration(
                                labelText: 'Clasificación máxima'),
                            items: parentalRatings
                                .map((value) => DropdownMenuItem(
                                    value: value, child: Text(value)))
                                .toList(),
                            onChanged: (value) =>
                                update(() => rating = value ?? 'TP'),
                          ),
                          TextFormField(
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: InputDecoration(
                                labelText: details.hasPin
                                    ? 'Nuevo PIN (opcional)'
                                    : 'PIN de acceso (opcional)'),
                            onChanged: (value) => pin = value,
                            validator: (value) => value != null &&
                                    value.isNotEmpty &&
                                    (value.length < 4 || value.length > 6)
                                ? 'Usa de 4 a 6 dígitos.'
                                : null,
                          ),
                          if (details.hasPin)
                            CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                value: removePin,
                                onChanged: (value) =>
                                    update(() => removePin = value ?? false),
                                title: const Text('Quitar PIN')),
                        ]))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () {
                        if (child &&
                            name == appState.activeProfile &&
                            !appState.profiles.any((profile) =>
                                profile != name &&
                                !appState.profileDetails(profile).isChild &&
                                appState.profileDetails(profile).hasPin)) {
                          update(() => setupError =
                              'Protege primero otro perfil adulto con un PIN.');
                          return;
                        }
                        if (form.currentState!.validate()) {
                          Navigator.pop(dialogContext, true);
                        }
                      },
                      child: const Text('Guardar')),
                ],
              ),
            ));
    final selectedAvatar =
        avatarUrl.text.trim().isEmpty ? avatar : avatarUrl.text.trim();
    avatarUrl.dispose();
    if (accepted != true || !mounted) return;
    await _save(() => appState.configureProfile(name,
        avatar: selectedAvatar,
        isChild: child,
        maxRating: rating,
        pin: removePin
            ? ''
            : pin.isEmpty
                ? null
                : pin));
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
    if (appState.profileDetails(name).hasPin &&
        await _requestPin(name) == null) {
      return;
    }
    if (!mounted) return;
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
              final childMode = appState.profileDetails(active ?? '').isChild;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    if (_saving)
                      const LinearProgressIndicator(
                        semanticsLabel: 'Guardando cambios',
                      ),
                    if (appState.profileSyncError != null) ...[
                      Text(appState.profileSyncError!),
                      TextButton(
                          onPressed: appState.retryProfileSync,
                          child: const Text('Reintentar sincronización')),
                    ],
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
                            avatar: appState.profileDetails(name).avatar,
                            isChild: appState.profileDetails(name).isChild,
                            hasPin: appState.profileDetails(name).hasPin,
                            selected: active == name,
                            showDelete: _editMode && !childMode,
                            onEdit: _saving || childMode
                                ? null
                                : () => _editProfile(name),
                            onTap: _saving || _editMode
                                ? null
                                : () => _selectProfile(name),
                            onDelete:
                                _saving ? null : () => _removeProfile(name),
                          ),
                        ),
                        _ProfileAvatar(
                          name: 'Agregar',
                          isAdd: true,
                          onTap: _saving || childMode ? null : _addProfile,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: _saving || childMode
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
  final String avatar;
  final bool isChild;
  final bool hasPin;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _ProfileAvatar({
    required this.name,
    required this.onTap,
    this.onDelete,
    this.selected = false,
    this.isAdd = false,
    this.showDelete = false,
    this.avatar = 'initials',
    this.isChild = false,
    this.hasPin = false,
    this.onEdit,
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
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
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
                                : avatar.startsWith('https://')
                                    ? ClipOval(
                                        child: Image.network(avatar,
                                            width: 64,
                                            height: 64,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.person,
                                                    color: Colors.white,
                                                    size: 32)))
                                    : avatar != 'initials'
                                        ? Icon(
                                            _avatarIcons[avatar] ??
                                                Icons.person,
                                            color: Colors.white,
                                            size: 32)
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
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (!isAdd && (isChild || hasPin))
                        Text(
                            [if (isChild) 'Infantil', if (hasPin) 'Protegido']
                                .join(' · '),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white70)),
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
          Wrap(alignment: WrapAlignment.center, children: [
            TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar')),
            TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar'),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
          ]),
      ],
    );
  }
}

const _avatarIcons = <String, IconData>{
  'person': Icons.person,
  'movie': Icons.movie,
  'pets': Icons.pets,
  'star': Icons.star,
};
const _avatarNames = <String, String>{
  'person': 'Persona',
  'movie': 'Cine',
  'pets': 'Mascota',
  'star': 'Estrella',
};
