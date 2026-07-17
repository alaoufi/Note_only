import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mudhakkarati/services/license_service.dart';

/// يحاكي ما يفعله المولّد المستقلّ (التوقيع) كي نتأكّد أنّ التطبيق يفكّ ويتحقّق
/// بنفس الصيغة تمامًا — دون إلزام أيّ مفتاح خاصّ في المستودع.
Future<String> _signKey(
    SimpleKeyPair kp, String deviceId, int duration) async {
  final ed = Ed25519();
  final msg = utf8.encode('UNIV1|$deviceId|$duration');
  final sig = await ed.sign(msg, keyPair: kp);
  final bytes = <int>[(duration >> 8) & 0xff, duration & 0xff, ...sig.bytes];
  return LicenseService.base32(bytes);
}

void main() {
  group('Base32 (Crockford-ish)', () {
    test('round-trips arbitrary bytes', () {
      final rnd = Random(42);
      for (var trial = 0; trial < 200; trial++) {
        final len = rnd.nextInt(70) + 1;
        final bytes = List<int>.generate(len, (_) => rnd.nextInt(256));
        final enc = LicenseService.base32(bytes);
        final dec = LicenseService.base32Decode(enc);
        // قد يضيف الترميز بتات حشو؛ نتحقّق من مطابقة أوّل len بايت.
        expect(dec.take(len).toList(), bytes,
            reason: 'فشل round-trip عند الطول $len');
      }
    });

    test('decoder ignores separators and lowercase noise', () {
      final bytes = [1, 2, 3, 4, 5, 250, 200, 33];
      final enc = LicenseService.base32(bytes);
      final messy = '  ${enc.substring(0, 4)}-${enc.substring(4)} \n';
      final dec = LicenseService.base32Decode(
          messy.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), ''));
      expect(dec.take(bytes.length).toList(), bytes);
    });
  });

  group('License key pipeline (generator → app)', () {
    test('valid key verifies; tamper & wrong-device fail', () async {
      final ed = Ed25519();
      final kp = await ed.newKeyPair();
      final pub = await kp.extractPublicKey();
      const deviceId = 'ABCD2345EFGH6789';
      const duration = 30;

      final key = await _signKey(kp, deviceId, duration);

      // جانب التطبيق: فكّ ثم تحقّق (يطابق tryActivate داخليًّا).
      final decoded = LicenseService.base32Decode(key);
      expect(decoded.length, 66, reason: 'مدّة(2) + توقيع(64)');
      final dur = (decoded[0] << 8) | decoded[1];
      expect(dur, duration);
      final sig = decoded.sublist(2);

      final goodMsg = utf8.encode('UNIV1|$deviceId|$dur');
      expect(
        await ed.verify(goodMsg, signature: Signature(sig, publicKey: pub)),
        isTrue,
      );

      // جهاز مختلف ⇒ يفشل (مربوط بالجهاز، لا ينتقل).
      final otherMsg = utf8.encode('UNIV1|ZZZZ2345EFGH6789|$dur');
      expect(
        await ed.verify(otherMsg, signature: Signature(sig, publicKey: pub)),
        isFalse,
      );

      // تلاعب بالتوقيع ⇒ يفشل.
      final bad = List<int>.of(sig)..[0] ^= 0xff;
      expect(
        await ed.verify(goodMsg, signature: Signature(bad, publicKey: pub)),
        isFalse,
      );

      // تلاعب بالمدّة ⇒ الرسالة تختلف ⇒ يفشل.
      final wrongDurMsg = utf8.encode('UNIV1|$deviceId|9999');
      expect(
        await ed.verify(wrongDurMsg, signature: Signature(sig, publicKey: pub)),
        isFalse,
      );
    });

    test('permanent (duration 0) encodes/decodes correctly', () async {
      final ed = Ed25519();
      final kp = await ed.newKeyPair();
      final key = await _signKey(kp, 'TESTDEVICE234567', 0);
      final decoded = LicenseService.base32Decode(key);
      final dur = (decoded[0] << 8) | decoded[1];
      expect(dur, 0); // 0 = دائم.
    });
  });

  // متجهات الاختبار الرسمية لنظام UNIV1 (من مستند المولّد): تتحقّق من أنّ التطبيق
  // متوافق تمامًا مع «مولّد أكواد التفعيل» — أي كود من المولّد سيُقبَل هنا.
  group('UNIV1 official vectors (matches the keygen app)', () {
    // المفتاح العامّ المدمج نفسه (نسخة من _publicKeyB64 في license_service.dart).
    const pub = '0JXPjbbPjczfYbYxl+jy1vOVcsEJT+CPbUIQgXNCStU=';
    const device = 'TESTDEVICE234567';
    const vectors = {
      0: 'AAANSJ2UELQ398JB5X4FPSV9DWUW3XSRP367RBVF9ASD7URBN55UTUBRMHWNYEQTL6HQLVS43XA5B3K7QK2ZU7FF4GX8PJB93BE4CKB2AJ',
      30: 'AARLNZUCVGUA827D3FUBNPHB9ESX6KZX4EWUEM7NX7LU2CJ5XX4JPZSBUPAWUDNKH2TAP2P7992LQ99UNV9HP55BME68X8EM8FBU69UBAJ',
    };

    test('official codes verify against the embedded public key', () async {
      final ed = Ed25519();
      final pk = SimplePublicKey(base64Decode(pub), type: KeyPairType.ed25519);
      for (final e in vectors.entries) {
        final bytes = LicenseService.base32Decode(e.value);
        expect(bytes.length, 66, reason: 'len for dur ${e.key}');
        expect((bytes[0] << 8) | bytes[1], e.key, reason: 'duration parse');
        final ok = await ed.verify(utf8.encode('UNIV1|$device|${e.key}'),
            signature: Signature(bytes.sublist(2), publicKey: pk));
        expect(ok, isTrue, reason: 'verify dur ${e.key}');
      }
    });

    test('a code for one device is rejected on another device', () async {
      final ed = Ed25519();
      final pk = SimplePublicKey(base64Decode(pub), type: KeyPairType.ed25519);
      final bytes = LicenseService.base32Decode(vectors[0]!);
      final ok = await ed.verify(utf8.encode('UNIV1|OTHERDEVICE12345|0'),
          signature: Signature(bytes.sublist(2), publicKey: pk));
      expect(ok, isFalse);
    });

    // النظام الموحّد الحالي UNI3: كودان رسميّان من مستند المولّد (نفس المفتاح
    // والبادئة UNI3) — يضمنان قبول التطبيق لأكواد المولّد الموحّد الواحد.
    test('أكواد UNI3 الرسمية تتحقّق بالمفتاح الموحّد وترفض جهازًا آخر', () async {
      final ed = Ed25519();
      const uni3Pub = 'W5Kc9hRB7lb9xSh/VqdR4T8GT6VaDznEwYQgXZpLZz0=';
      const device = 'JGNKT87QXZ4AZVBE';
      final pk =
          SimplePublicKey(base64Decode(uni3Pub), type: KeyPairType.ed25519);
      const vectors = {
        0: 'AAAA-NNHY-8FJL-25Z5-WYXN-LWFL-868F-YST9-C9XR-94AN-ECKZ-LSL9-'
            'LCYH-KDT9-UP57-TF8N-UC62-S26J-AM8U-ATFL-QP6B-SR7L-N8HX-HNHT-'
            '85QZ-7ATT-BE',
        30: 'AARL-CPHN-6DH2-X3QY-EAUF-RAD3-PF8A-5PDU-PBXQ-7LV8-PH93-VD8P-'
            '7DPZ-TGDS-S64Z-JKUL-LSF6-SGY3-GTG9-3BY2-3DKP-SUSX-ACSD-KP6R-'
            'XRE5-QB7X-B2',
      };
      for (final e in vectors.entries) {
        final bytes = LicenseService.base32Decode(
            e.value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), ''));
        expect(bytes.length, 66, reason: 'len dur ${e.key}');
        expect((bytes[0] << 8) | bytes[1], e.key, reason: 'duration ${e.key}');
        final ok = await ed.verify(utf8.encode('UNI3|$device|${e.key}'),
            signature: Signature(bytes.sublist(2), publicKey: pk));
        expect(ok, isTrue, reason: 'UNI3 verify dur ${e.key}');
      }
      // الكود نفسه لا يصلح لجهاز مختلف.
      final b0 = LicenseService.base32Decode(
          vectors[0]!.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), ''));
      final wrong = await ed.verify(utf8.encode('UNI3|OTHERDEVICE1234X|0'),
          signature: Signature(b0.sublist(2), publicKey: pk));
      expect(wrong, isFalse);
    });

    // كود حقيقي من «مولّد أكواد التفعيل» (mdk_keygen) للمالك — يضمن أنّ المفتاح
    // الأصلي يبقى مقبولًا في التطبيق كي يعمل المولّد الجاهز دائمًا.
    test('كود المولّد الجاهز (mdk_keygen) يتحقّق بالمفتاح الأصلي', () async {
      final ed = Ed25519();
      final pk = SimplePublicKey(base64Decode(pub), type: KeyPairType.ed25519);
      const device = 'JGNKT87QXZ4AZVBE';
      const code = 'AAAAL-GY7XD-75BEZ-DLWH9-UC362-S23MQ-WDZQ7-H8UUE-BUDL6-'
          'KGECD-GH4EY-CHXH7-MCGTS-AYU3C-3QYAK-RC9FK-EZ5WL-34JDK-5U64W-'
          '7BBDK-XF65A-E';
      final bytes = LicenseService.base32Decode(
          code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), ''));
      expect(bytes.length, 66);
      final dur = (bytes[0] << 8) | bytes[1];
      expect(dur, 0); // دائم.
      final ok = await ed.verify(utf8.encode('UNIV1|$device|$dur'),
          signature: Signature(bytes.sublist(2), publicKey: pk));
      expect(ok, isTrue);
    });
  });
}
