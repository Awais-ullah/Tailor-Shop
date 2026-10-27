import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_app/core/utils/phone_utils.dart';

void main() {
  group('PhoneUtils.normalize', () {
    test('the same Pakistani number written three ways compares equal', () {
      expect(PhoneUtils.normalize('0300-1234567'), '03001234567');
      expect(PhoneUtils.normalize('+92 300 1234567'), '03001234567');
      expect(PhoneUtils.normalize('0092 300 1234567'), '03001234567');
    });

    test('short numbers starting with 92 are left alone', () {
      expect(PhoneUtils.normalize('9212345'), '9212345');
    });

    test('empty input stays empty', () {
      expect(PhoneUtils.normalize('  '), '');
    });
  });

  group('PhoneUtils.validateOptional', () {
    test('empty is allowed, too short or too long is not', () {
      expect(PhoneUtils.validateOptional(''), isNull);
      expect(PhoneUtils.validateOptional('0300 1234567'), isNull);
      expect(PhoneUtils.validateOptional('12345'), isNotNull);
      expect(PhoneUtils.validateOptional('1234567890123456'), isNotNull);
    });
  });
}
