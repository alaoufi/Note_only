import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mudhakkarati/services/encryption_service.dart';

Uint8List _hex(String h) {
  final out = Uint8List(h.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(h.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

void main() {
  final svc = EncryptionService.instance;
  final data = Uint8List.fromList(
      utf8.encode('ملاحظة سرّية — secret note 12345 \n سطر ثانٍ'));

  group('PBKDF2-HMAC-SHA256 standard vectors', () {
    // متجهات اختبار قياسية تثبت صحّة التنفيذ (لا حاجة لجهاز).
    final salt = Uint8List.fromList(utf8.encode('salt'));
    test('c=1, dkLen=32', () {
      expect(
          svc.pbkdf2('password', salt, 1, 32),
          _hex(
              '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b'));
    });
    test('c=2, dkLen=32', () {
      expect(
          svc.pbkdf2('password', salt, 2, 32),
          _hex(
              'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43'));
    });
    test('c=4096, dkLen=32', () {
      expect(
          svc.pbkdf2('password', salt, 4096, 32),
          _hex(
              'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a'));
    });
    test('multi-block dkLen=64 (passwd/salt/c=1) — RFC 7914', () {
      expect(
          svc.pbkdf2('passwd', salt, 1, 64),
          _hex('55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57'
              'c20dacbc49ca9cccf179b645991664b39d77ef317c71b845b1e30bd5'
              '09112041d3a19783'));
    });
  });

  group('authenticated backup encryption', () {
    test('roundtrip preserves data and uses authenticated format', () {
      final out = svc.encryptBytes(data, 'p@ss');
      expect(utf8.decode(out.sublist(0, 4)), 'MDK3'); // PBKDF2 مصادَق
      final back = svc.decryptBytes(out, 'p@ss');
      expect(back, data);
    });

    test('wrong password is rejected (not silent garbage)', () {
      final out = svc.encryptBytes(data, 'correct');
      expect(() => svc.decryptBytes(out, 'wrong'),
          throwsA(isA<FormatException>()));
    });

    test('tampering with the ciphertext is detected (HMAC)', () {
      final out = svc.encryptBytes(data, 'p@ss');
      final tampered = Uint8List.fromList(out);
      tampered[tampered.length - 1] ^= 0xFF; // قلب آخر بايت
      expect(() => svc.decryptBytes(tampered, 'p@ss'),
          throwsA(isA<FormatException>()));
    });
  });
}
