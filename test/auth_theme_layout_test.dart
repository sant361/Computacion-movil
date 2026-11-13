import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streaming_app/screens/auth/login_screen.dart';
import 'package:streaming_app/screens/auth/register_screen.dart';
import 'package:streaming_app/screens/auth/forgot_password_screen.dart';
import 'package:streaming_app/theme/app_theme.dart';

void main() {
  for (final screen in <Widget>[
    const LoginScreen(),
    const RegisterScreen(),
    const ForgotPasswordScreen(),
  ]) {
    testWidgets('${screen.runtimeType} funciona con teclado y texto ampliado',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.dark,
          home: MediaQuery(
              data: MediaQueryData.fromView(tester.view)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: screen)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.byType(ElevatedButton), 200, scrollable: find.byType(Scrollable).first);
      final button = find.byType(ElevatedButton).last;
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      expect(button.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

