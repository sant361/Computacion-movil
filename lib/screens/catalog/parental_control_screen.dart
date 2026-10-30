import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/catalog_item.dart';
import '../../state/app_state.dart';

/// Req. 41: control parental y clasificación máxima de contenido.
class ParentalControlScreen extends StatefulWidget {
  const ParentalControlScreen({super.key});

  @override
  State<ParentalControlScreen> createState() => _ParentalControlScreenState();
}

class _ParentalControlScreenState extends State<ParentalControlScreen> {
  late String _maxRating = appState.parentalMaxRating;
  late bool _restrictByProfile = appState.parentalRestrictByProfile;
  late bool _blockPurchases = appState.parentalBlockPurchases;
  late final _pinController = TextEditingController(text: appState.parentalPin);

  Future<void> _save() async {
    final pin = _pinController.text;
    if (pin.isNotEmpty && pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El PIN debe tener 4 dígitos (o déjalo vacío)')),
      );
      return;
    }
    await appState.saveParentalSettings(
      maxRating: _maxRating,
      restrictByProfile: _restrictByProfile,
      blockPurchases: _blockPurchases,
      pin: pin,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Control parental actualizado')),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control parental')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Clasificación máxima', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: parentalRatings.map((r) {
              return ChoiceChip(
                label: Text(r),
                selected: _maxRating == r,
                onSelected: (_) => setState(() => _maxRating = r),
              );
            }).toList(),
          ),
          const Divider(height: 32),
          const Text('PIN de control parental', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 4,
            decoration: const InputDecoration(hintText: '••••'),
          ),
          const Divider(),
          SwitchListTile(
            value: _restrictByProfile,
            onChanged: (v) => setState(() => _restrictByProfile = v),
            title: const Text('Restringir por perfil'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _blockPurchases,
            onChanged: (v) => setState(() => _blockPurchases = v),
            title: const Text('Bloquear compras'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('GUARDAR CAMBIOS'),
            ),
          ),
        ],
      ),
    );
  }
}
