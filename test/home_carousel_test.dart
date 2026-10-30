import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streaming_app/screens/content_detail_screen.dart';
import 'package:streaming_app/screens/home_screen.dart';

void main() {
  testWidgets('el deslizamiento actualiza el título y su acción en móvil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    final pages = find.byType(PageView);
    expect(
      tester.widget<PageView>(pages).childrenDelegate.estimatedChildCount,
      5,
    );
    expect(find.byTooltip('Título siguiente'), findsNothing);
    await tester.drag(pages, const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: pages, matching: find.text('La última broma')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: pages,
        matching: find.text('2022  ·  Comedia  ·  Serie'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(of: pages, matching: find.text('Reproducir')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ContentDetailScreen>(find.byType(ContentDetailScreen))
          .title,
      'La última broma',
    );
  });

  testWidgets('las flechas e indicadores navegan sin avance automático', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_left),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Título siguiente'));
    await tester.pumpAndSettle();
    final controller = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;
    expect(controller.page, 1);
    await tester.pump(const Duration(seconds: 20));
    expect(controller.page, 1);

    await tester.tap(find.byTooltip('Ver título 5 de 5'));
    await tester.pumpAndSettle();
    expect(controller.page, 4);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_right),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
