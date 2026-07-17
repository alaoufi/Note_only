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

  group('Universal code (الكود العالمي — أيّ جهاز)', () {
    test('كود موقّع على «*» يتحقّق لأيّ جهاز، ورمز جهاز محدّد لا يعمل عالميًّا',
        () async {
      final ed = Ed25519();
      final kp = await ed.newKeyPair();
      final pub = await kp.extractPublicKey();

      // الكود العالمي: يوقَّع على الجهاز البديل «*».
      final universal = await _signKey(kp, '*', 0);
      final decoded = LicenseService.base32Decode(universal);
      final dur = (decoded[0] << 8) | decoded[1];
      final sig = decoded.sublist(2);

      // يطابق منطق tryActivate: نجرّب رسالة الجهاز ثم الرسالة العالمية «*».
      Future<bool> activates(String deviceId) async {
        final deviceMsg = utf8.encode('UNIV1|$deviceId|$dur');
        final universalMsg = utf8.encode('UNIV1|*|$dur');
        return await ed.verify(deviceMsg,
                signature: Signature(sig, publicKey: pub)) ||
            await ed.verify(universalMsg,
                signature: Signature(sig, publicKey: pub));
      }

      // الكود العالمي يفعّل أيّ جهاز مهما كان معرّفه.
      expect(await activates('ABCD2345EFGH6789'), isTrue);
      expect(await activates('ZZZZ9999QQQQ8888'), isTrue);

      // بينما رمز خاصّ بجهاز واحد لا يصلح كودًا عالميًّا لجهاز آخر.
      final perDevice = await _signKey(kp, 'ABCD2345EFGH6789', 0);
      final d2 = LicenseService.base32Decode(perDevice);
      final sig2 = d2.sublist(2);
      final otherOk = await ed.verify(utf8.encode('UNIV1|OTHERDEVICE12345|0'),
              signature: Signature(sig2, publicKey: pub)) ||
          await ed.verify(utf8.encode('UNIV1|*|0'),
              signature: Signature(sig2, publicKey: pub));
      expect(otherOk, isFalse);
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
  });
}
