import 'package:flutter/material.dart';
import '../../state/app_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: const Text('Notificaciones')),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            SwitchListTile(
              title: const Text('Avisos de estrenos'),
              subtitle: const Text(
                  'Recibe avisos aquí cuando haya nuevos títulos o episodios.'),
              value: appState.notificationsEnabled,
              onChanged: appState.setNotificationsEnabled,
            ),
            const Divider(height: 32),
            if (appState.notifications.isEmpty)
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child:
                      Center(child: Text('No hay nuevos avisos por ahora.'))),
            ...appState.notifications.map((notification) => ListTile(
                  leading: Icon(notification.read
                      ? Icons.notifications_none
                      : Icons.notifications_active_outlined),
                  title: Text(notification.title,
                      style: TextStyle(
                          fontWeight: notification.read
                              ? FontWeight.normal
                              : FontWeight.bold)),
                  subtitle: Text(notification.detail),
                  trailing: notification.read
                      ? null
                      : const Icon(Icons.circle, size: 8),
                  onTap: () => appState.markNotificationRead(notification.id),
                )),
          ]),
        ),
      );
}
