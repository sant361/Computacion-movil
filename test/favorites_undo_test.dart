import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_app/screens/catalog/my_list_screen.dart';
import 'package:streaming_app/state/app_state.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final changeProfile in [false, true]) {
    testWidgets('deshacer respeta el perfil: cambio=$changeProfile',
        (tester) async {
      await appState.loadProfiles('undo-$changeProfile');
      final title = appState.catalog.first.title;
      if (!appState.isInMyList(title)) appState.toggleMyList(title);
      await tester.pumpWidget(const MaterialApp(home: MyListScreen()));
      await tester.tap(find.byTooltip('Quitar $title de Mi lista'));
      await tester.pump();
      expect(appState.isInMyList(title), isFalse);
      if (changeProfile) await appState.setActiveProfile('Luis');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Deshacer'));
      await tester.pump();
      expect(appState.isInMyList(title), !changeProfile);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
}

