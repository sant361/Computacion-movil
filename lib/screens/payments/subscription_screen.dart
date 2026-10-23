import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../state/app_state.dart';
import '../account/devices_screen.dart';
import '../account/security_screen.dart';
import '../auth/login_screen.dart';
import 'billing_screen.dart';
import 'payment_methods_screen.dart';
import 'plans_screen.dart';

/// vistas cuenta, ajustes, suscripcion.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}
class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const _background = Color(0xFF07111F);
  static const _surface = Color(0xFF142338);
  static const _accent = Color(0xFF35D0C4);
  static const _red = Color(0xFFFC093F);
  static const _demoAuthEnabled = bool.fromEnvironment('DEMO_AUTH_ENABLED');

  bool _autoRenew = true;
  Uint8List? _avatarBytes;

  User? get _user =>
      kIsWeb && _demoAuthEnabled ? null : FirebaseAuth.instance.currentUser;

  String get _photoKey =>
      'account_photo:${_user?.uid ?? 'local'}:${appState.activeProfile ?? 'account'}';

  String get _displayName {
    final profile = appState.activeProfile?.trim();
    if (profile != null && profile.isNotEmpty) return profile;
    final name = _user?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = _user?.email;
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return _demoAuthEnabled ? 'Usuario demo' : 'Mi perfil';
  }

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final saved = (await SharedPreferences.getInstance()).getString(_photoKey);
    if (!mounted || saved == null) return;
    try {
      setState(() => _avatarBytes = base64Decode(saved));
    } on FormatException {
      // Una foto guardada inválida no debe impedir abrir los ajustes.
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      if (bytes.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_photoKey, base64Encode(bytes));
      if (mounted) setState(() => _avatarBytes = bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudo cargar la foto. Intenta de nuevo.')),
      );
    }
  }

  void _open(Widget screen) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );

  Future<void> _cancelPlan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('¿Cancelar tu plan?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Seguirás con acceso hasta el final del periodo ya pagado. Después no se renovará.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Mantener mi plan'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar cancelación',
                style: TextStyle(color: _red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        final user = _user;
        if (user == null) {
          throw StateError('No hay una sesión autenticada');
        }
        await FirebaseFirestore.instance
            .collection('subscriptions')
            .doc(user.uid)
            .update({
          'cancelAtPeriodEnd': true,
          'autoRenew': false,
          'cancellationRequestedAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        setState(() => _autoRenew = false);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se pudo cancelar el plan. Intenta de nuevo.')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tu plan se cancelará al final del periodo')),
      );
    }
  }

  Future<void> _signOut() async {
    if (!(kIsWeb && _demoAuthEnabled)) await FirebaseAuth.instance.signOut();
    await appState.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 28, 4, 12),
        child: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      );

  Widget _settingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    bool destructive = false,
  }) =>
      Material(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          leading: Icon(icon, color: destructive ? _red : _accent),
          title: Text(title,
              style: TextStyle(
                  color: destructive ? _red : Colors.white,
                  fontWeight: FontWeight.w600)),
          subtitle: subtitle == null
              ? null
              : Text(subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
          trailing: destructive
              ? null
              : const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          onTap: onTap,
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) => Scaffold(
          backgroundColor: _background,
          appBar: AppBar(
            backgroundColor: _background,
            foregroundColor: Colors.white,
            title: const Text('Mi perfil',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          body: SafeArea(
              child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF267C83),
                      Color(0xFF173B54),
                      Color(0xFF101A31)
                    ],
                  ),
                ),
                child: Row(children: [
                  InkWell(
                    onTap: _pickPhoto,
                    borderRadius: BorderRadius.circular(48),
                    child: Stack(clipBehavior: Clip.none, children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: _surface,
                        backgroundImage: _avatarBytes == null
                            ? null
                            : MemoryImage(_avatarBytes!),
                        child: _avatarBytes == null
                            ? const Icon(Icons.person_rounded,
                                size: 40, color: Colors.white)
                            : null,
                      ),
                      const Positioned(
                        right: -3,
                        bottom: -3,
                        child: CircleAvatar(
                          radius: 13,
                          backgroundColor: _accent,
                          child: Icon(Icons.camera_alt_rounded,
                              size: 15, color: _background),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      const Text('Plan Estándar',
                          style: TextStyle(
                              color: _accent, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      const Text('Vencimiento no disponible',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  )),
                ]),
              ),
              const SizedBox(height: 9),
              TextButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: const Text('Cambiar foto de perfil'),
                style: TextButton.styleFrom(foregroundColor: _accent),
              ),
              _sectionTitle('Mi plan'),
              Container(
                decoration: BoxDecoration(
                    color: _surface, borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Estándar',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      const Text('Fecha de renovación por confirmar',
                          style: TextStyle(color: Colors.white60)),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        activeTrackColor: _accent,
                        title: const Text('Renovación automática',
                            style: TextStyle(color: Colors.white)),
                        value: _autoRenew,
                        onChanged: (value) =>
                            setState(() => _autoRenew = value),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => _open(const PlansScreen()),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: _accent,
                            side: const BorderSide(color: _accent)),
                        child: const Text('Cambiar plan'),
                      ),
                      OutlinedButton(
                        onPressed: _cancelPlan,
                        style: OutlinedButton.styleFrom(
                            foregroundColor: _red,
                            side: const BorderSide(color: _red)),
                        child: const Text('Cancelar plan'),
                      ),
                    ]),
              ),
              _sectionTitle('Pagos'),
              _settingTile(
                icon: Icons.credit_card_rounded,
                title: 'Métodos de pago',
                onTap: () async {
                  await appState.loadPaymentMethods(_user?.uid ?? 'local');
                  if (mounted) _open(const PaymentMethodsScreen());
                },
              ),
              const SizedBox(height: 8),
              _settingTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Facturación',
                  onTap: () => _open(const BillingScreen())),
              _sectionTitle('Cuenta y seguridad'),
              _settingTile(
                  icon: Icons.shield_outlined,
                  title: 'Seguridad',
                  onTap: () => _open(const SecurityScreen())),
              const SizedBox(height: 8),
              _settingTile(
                  icon: Icons.devices_rounded,
                  title: 'Dispositivos',
                  onTap: () => _open(const DevicesScreen())),
              const SizedBox(height: 24),
              _settingTile(
                  icon: Icons.logout_rounded,
                  title: 'Cerrar sesión',
                  destructive: true,
                  onTap: _signOut),
            ],
          )),
        ),
      );
}
