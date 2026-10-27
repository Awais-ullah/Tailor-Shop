import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';
import 'package:tailor_app/core/theme/app_theme.dart';
import 'package:tailor_app/features/shell/presentation/widgets/app_bottom_bar.dart';
import 'package:tailor_app/features/shell/presentation/widgets/quick_add_sheet.dart';

/// The phone bottom bar on its own: four tabs around the centre "+".
void main() {
  tearDown(() => S.setLanguage('en'));

  Future<List<int>> pump(
    WidgetTester tester, {
    double textScale = 1.0,
    String language = 'en',
    VoidCallback? onAdd,
  }) async {
    S.setLanguage(language);
    final taps = <int>[];
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Directionality(
          textDirection: AppLanguage.byCode(language)!.rtl
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(
              size: const Size(360, 720),
              textScaler: TextScaler.linear(textScale),
            ),
            child: Scaffold(
              floatingActionButton: QuickAddButton(onPressed: onAdd ?? () {}),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              bottomNavigationBar: AppBottomBar(
                selectedIndex: 0,
                onSelected: taps.add,
                items: [
                  for (final label in [
                    S.current.home,
                    S.current.customers,
                    S.current.orders,
                    S.current.more,
                  ])
                    BottomBarItem(
                      label: label,
                      icon: Icons.circle_outlined,
                      selectedIcon: Icons.circle,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return taps;
  }

  testWidgets('tapping a tab reports its index', (tester) async {
    final taps = await pump(tester);

    await tester.tap(find.text(S.current.customers));
    await tester.tap(find.text(S.current.more));
    expect(taps, [1, 3]);
  });

  testWidgets('the selected tab is marked selected', (tester) async {
    await pump(tester);

    expect(
      tester.getSemantics(find.bySemanticsLabel(S.current.home)),
      matchesSemantics(
        label: S.current.home,
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
      ),
    );
  });

  testWidgets('the centre button is called when tapped', (tester) async {
    var added = 0;
    await pump(tester, onAdd: () => added++);

    await tester.tap(find.byType(QuickAddButton));
    expect(added, 1);
  });

  for (final language in ['en', 'ur', 'ru']) {
    testWidgets('fits a 360 px phone at 1.5x text ($language)', (
      tester,
    ) async {
      await pump(tester, textScale: 1.5, language: language);
      expect(tester.takeException(), isNull);
    });
  }

  test('the notch shape is closed and clears the button', () {
    const host = Rect.fromLTWH(0, 600, 360, 68);
    // The button (radius 30) plus the 8 px notch margin, centred on the
    // top edge like a centre-docked button.
    final guest = Rect.fromCircle(center: const Offset(180, 600), radius: 38);
    final path = const SmoothNotchedShape().getOuterPath(host, guest);

    // Inside the bar on the left and right, but not under the button.
    expect(path.contains(const Offset(20, 650)), isTrue);
    expect(path.contains(const Offset(340, 650)), isTrue);
    expect(path.contains(const Offset(180, 620)), isFalse);
    expect(path.contains(const Offset(180, 660)), isTrue);
  });
}
