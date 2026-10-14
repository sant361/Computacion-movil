import 'package:flutter/material.dart';

/// Req. 56, 61, 66: disponibilidad por región, dispositivos y alertas de seguridad.
class RegionSecurityScreen extends StatefulWidget {
  const RegionSecurityScreen({super.key});

  @override
  State<RegionSecurityScreen> createState() => _RegionSecurityScreenState();
}

class _RegionSecurityScreenState extends State<RegionSecurityScreen> {
  final Map<String, bool> _regions = {'Colombia': true, 'México': true, 'España': false};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Región y seguridad')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Disponibilidad por territorio', style: TextStyle(fontWeight: FontWeight.bold)),
          ..._regions.keys.map(
            (r) => SwitchListTile(
              title: Text(r),
              value: _regions[r]!,
              onChanged: (v) => setState(() => _regions[r] = v),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const Divider(height: 32),
          const Text('Dispositivos autorizados', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Límite por plan: 4 dispositivos', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abriendo dispositivos autorizados (demo)'))), child: const Text('Pantalla Dispositivos')),
          const Divider(height: 32),
          Card(
            color: const Color(0xFFFFF7E8),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.orange),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const ListTile(
              leading: Icon(Icons.flag_outlined, color: Colors.orange),
              title: Text('Actividad inusual detectada', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('3 accesos desde ubicaciones distintas en 1 hora.'),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abriendo alertas de seguridad (demo)'))), child: const Text('Ver alertas de seguridad')),
        ],
      ),
    );
  }
}
