import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../state/app_state.dart';
import '../../widgets/primary_button.dart';

/// Req. 11: formulario para agregar un nuevo método de pago.
class AddPaymentMethodScreen extends StatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  bool _saveAsDefault = true;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Identifica la marca de la tarjeta por su primer dígito, solo para
  /// mostrarla en pantalla (no hay cobro ni validación real con un banco).
  String _brandFromCardNumber(String cardNumber) {
    if (cardNumber.startsWith('4')) return 'Visa';
    if (cardNumber.startsWith('5')) return 'Mastercard';
    return 'Tarjeta';
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final cardNumber = _cardNumberController.text;
      await appState.addPaymentMethod(
        last4: cardNumber.substring(cardNumber.length - 4),
        brand: _brandFromCardNumber(cardNumber),
        expiry: _expiryController.text,
        holder: _nameController.text.trim(),
        isDefault: _saveAsDefault,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Método de pago guardado')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar método')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.credit_card),
                  labelText: 'Número de tarjeta',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
                validator: (v) =>
                    (v == null || v.length != 16) ? 'Debe tener 16 dígitos' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      decoration: const InputDecoration(labelText: 'MM/AA', hintText: '08/28'),
                      inputFormatters: [LengthLimitingTextInputFormatter(5)],
                      validator: (v) {
                        final pattern = RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$');
                        return (v == null || !pattern.hasMatch(v)) ? 'Formato MM/AA' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: const InputDecoration(labelText: 'CVV'),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                      validator: (v) =>
                          (v == null || v.length < 3) ? 'CVV inválido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre del titular'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre del titular' : null,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _saveAsDefault,
                onChanged: (v) => setState(() => _saveAsDefault = v ?? true),
                title: const Text('Guardar como principal'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tus datos se guardan cifrados',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              const SizedBox(height: 12),
              PrimaryButton(label: 'GUARDAR MÉTODO', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
