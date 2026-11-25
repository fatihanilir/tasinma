import 'package:ev_hesap_app/widgets/keyboard_dismiss_bar.dart';
import 'package:ev_hesap_app/widgets/text_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'en alttaki alan klavyenin üstünde görünür, çubuk klavyeyi kapatır',
    (tester) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(1170, 2532); // 390 x 844
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => KeyboardVisibility(
              isOpen: KeyboardVisibility.openFrom(context),
              child: Scaffold(
                resizeToAvoidBottomInset: true,
                body: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 1500),
                            TextInputCard(
                              label: 'Başlık',
                              value: '',
                              onChanged: (_) {},
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                    const KeyboardDismissBar(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Klavyeyi kapat'), findsNothing);

      await tester.showKeyboard(find.byType(TextField));
      tester.view.viewInsets = const FakeViewPadding(bottom: 336 * 3);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Caddebostan');
      await tester.pumpAndSettle();

      final bar = tester.getRect(find.byType(KeyboardDismissBar));
      final field = tester.getRect(find.byType(TextField));
      expect(find.text('Klavyeyi kapat'), findsOneWidget);
      expect(bar.bottom, lessThanOrEqualTo(844 - 336));
      expect(field.bottom, lessThanOrEqualTo(bar.top));
      expect(field.top, greaterThanOrEqualTo(0));

      await tester.tap(find.text('Klavyeyi kapat'));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isFalse);

      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(find.text('Klavyeyi kapat'), findsNothing);
    },
  );
}
