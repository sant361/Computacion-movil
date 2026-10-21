import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../l10n/app_text.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const AppText('Idioma')),
    body: ListenableBuilder(
      listenable: appState,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppText('Selecciona el idioma de la aplicación'),
          const SizedBox(height: 16),
          for (final language in const {'es': 'Español', 'en': 'English', 'fr': 'Français'}.entries)
            Card(child: ListTile(
              leading: const Icon(Icons.language),
              title: AppText(language.value),
              trailing: appState.languageCode == language.key
                  ? const Icon(Icons.check, color: Colors.lightBlueAccent) : null,
              onTap: () async {
                try {
                  await appState.setLanguage(language.key);
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: AppText('No se pudo guardar. Intenta de nuevo.')),
                  );
                }
              },
            )),
        ],
      ),
    ),
  );
}
