import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_app/core/utils/inch_format.dart';
import 'package:tailor_app/core/utils/money.dart';
import 'package:tailor_app/features/orders/data/models/order_item.dart';
import 'package:tailor_app/features/orders/data/order_money.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';

void main() {
  group('OrderMoney', () {
    test('total adds quantity x price for every item', () {
      const items = [
        OrderItem(name: 'Shalwar Kameez', quantity: 2, unitPrice: 2500),
        OrderItem(name: 'Waistcoat', quantity: 1, unitPrice: 3000),
      ];
      expect(OrderMoney.total(items), 8000);
    });

    test('remaining = total - paid', () {
      expect(OrderMoney.remaining(total: 5000, paid: 3000), 2000);
      expect(OrderMoney.remaining(total: 5000, paid: 5000), 0);
    });

    test('payment status follows the amount paid', () {
      expect(OrderMoney.paymentStatus(total: 5000, paid: 0), PaymentStatus.unpaid);
      expect(OrderMoney.paymentStatus(total: 5000, paid: 2000), PaymentStatus.partial);
      expect(OrderMoney.paymentStatus(total: 5000, paid: 5000), PaymentStatus.paid);
    });
  });

  group('Money', () {
    test('formats rupees with lakh grouping', () {
      expect(Money.pkr(5000), 'Rs. 5,000');
      expect(Money.pkr(100000), 'Rs. 1,00,000');
    });
  });

  group('InchFormat.parse', () {
    test('reads decimals, fractions and fraction symbols', () {
      expect(InchFormat.parse('15'), 15);
      expect(InchFormat.parse('15.5'), 15.5);
      expect(InchFormat.parse('15 1/2'), 15.5);
      expect(InchFormat.parse('15½'), 15.5);
      expect(InchFormat.parse('1/2'), 0.5);
    });

    test('rejects text that is not a number', () {
      expect(InchFormat.parse(''), isNull);
      expect(InchFormat.parse('abc'), isNull);
    });
  });

  group('InchFormat.format', () {
    test('shows exact eighths as fractions', () {
      expect(InchFormat.format(15.5), '15½');
      expect(InchFormat.format(40.25), '40¼');
      expect(InchFormat.format(40), '40');
    });

    test('shows anything else as a decimal, never rounded to a fraction', () {
      expect(InchFormat.format(15.3), '15.3');
    });
  });

  group('InchFormat.validateOptional', () {
    test('allows empty, rejects zero and too large', () {
      expect(InchFormat.validateOptional(''), isNull);
      expect(InchFormat.validateOptional('0'), isNotNull);
      expect(InchFormat.validateOptional('151'), isNotNull);
      expect(InchFormat.validateOptional('40'), isNull);
    });
  });
}