import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_app/core/currency/currency_controller.dart';
import 'package:tailor_app/core/theme/app_theme.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';
import 'package:tailor_app/features/orders/data/models/order_item.dart';
import 'package:tailor_app/features/orders/presentation/widgets/order_form_parts.dart';

void main() {
  setUp(() => CurrencyController.instance.value = AppCurrency.pkr);

  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  group('OrderItemsCard', () {
    const items = [
      OrderItem(name: 'Shalwar Kameez', quantity: 2, unitPrice: 2500),
      OrderItem(name: 'Waistcoat', quantity: 1, unitPrice: 3000),
    ];

    testWidgets('shows every item and the total', (tester) async {
      await pump(
        tester,
        OrderItemsCard(items: items, onEdit: (_) {}, onDelete: (_) {}),
      );
      expect(find.byType(OrderItemRow), findsNWidgets(2));
      expect(find.text('Rs. 8,000'), findsOneWidget);
    });

    testWidgets('editing reports the tapped row', (tester) async {
      int? edited;
      await pump(
        tester,
        OrderItemsCard(
          items: items,
          onEdit: (i) => edited = i,
          onDelete: (_) {},
        ),
      );
      await tester.tap(find.byType(OrderItemRow).last);
      expect(edited, 1);
    });

    testWidgets('explains when there are no items', (tester) async {
      await pump(
        tester,
        OrderItemsCard(items: const [], onEdit: (_) {}, onDelete: (_) {}),
      );
      expect(find.text(S.current.noItemsYet), findsOneWidget);
      expect(find.text('Rs. 0'), findsOneWidget);
    });
  });

  testWidgets('no attached measurements shows a note', (tester) async {
    await pump(
      tester,
      AttachedMeasurementsList(attached: const [], onRemove: (_) {}),
    );
    expect(find.text(S.current.noMeasurementsAttached), findsOneWidget);
  });

  group('OrderFormActions', () {
    testWidgets('both buttons work when not saving', (tester) async {
      var saved = false;
      var cancelled = false;
      await pump(
        tester,
        OrderFormActions(
          saving: false,
          saveLabel: 'Create order',
          onCancel: () => cancelled = true,
          onSave: () => saved = true,
        ),
      );
      await tester.tap(find.text('Create order'));
      await tester.tap(find.text(S.current.cancel));
      expect(saved, isTrue);
      expect(cancelled, isTrue);
    });

    testWidgets('both buttons are disabled while saving', (tester) async {
      await pump(
        tester,
        OrderFormActions(
          saving: true,
          saveLabel: 'Create order',
          onCancel: () => fail('cancel should be disabled'),
          onSave: () => fail('save should be disabled'),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      await tester.tap(find.byType(OutlinedButton));
    });
  });
}
