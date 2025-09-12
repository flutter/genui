import 'package:test/test.dart';
import 'package:dart_schema_builder/dart_schema_builder.dart';
import '../lib/src/formats.dart';

void main() {
  group('FormatValidator', () {
    test('email validator should accept valid emails', () {
      final validator = formatValidators['email']!;
      expect(validator('test@example.com'), isTrue);
      expect(validator('user.name+tag@example.co.uk'), isTrue);
      expect(validator('123@abc.org'), isTrue);
      expect(validator('a@b.io'), isTrue); // minimal valid
    });

    test('email validator should reject invalid emails', () {
      final validator = formatValidators['email']!;
      expect(validator(''), isFalse);
      expect(validator('@example.com'), isFalse);
      expect(validator('test@'), isFalse);
      expect(validator('test@example'), isFalse);
      expect(validator('test@.com'), isFalse);
      expect(validator('test@com.'), isFalse);
      expect(validator('test@@example.com'), isFalse);
      expect(validator('test@ex ample.com'), isFalse); // space not allowed
      expect(validator('test@x'), isFalse); // TLD too short
    });
  });
}
