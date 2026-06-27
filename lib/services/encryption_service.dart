import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart' show visibleForTesting;

/// تشفير/فك تشفير بيانات النسخ الاحتياطية باستخدام AES-256.
///
/// المفتاح يُشتق من كلمة مرور المستخدم عبر **PBKDF2-HMAC-SHA256** (الصيغة MDK3).
/// كل شيء يتم داخل الجهاز — لا يُرسل أي شيء للخارج.
class EncryptionService {
  EncryptionService._();
  static final EncryptionService instance = EncryptionService._();

  static const _magic = 'MDK1'; // قديم: AES-CBC بلا مصادقة (يُقرأ للتوافق)
  static const _magic2 = 'MDK2'; // قديم: AES-CBC + HMAC، اشتقاق SHA-256 مكرّر
  static const _magic3 = 'MDK3'; // حاليّ: AES-CBC + HMAC، اشتقاق PBKDF2 قياسي
  // اشتقاق MDK2/MDK1 القديم (سلسلة SHA-256 مخصّصة، 12 ألف دورة) — يُبقى للقراءة فقط.
  static const _legacyIterations = 12000;
  // PBKDF2 القياسي (توصية OWASP 2023 لـ PBKDF2-HMAC-SHA256). يُخزَّن العدد في
  // ترويسة MDK3 كي تبقى النسخ القديمة قابلة للفكّ لو رُفع العدد مستقبلًا.
  static const _pbkdf2Iterations = 210000;

  /// اشتقاق قياسي PBKDF2-HMAC-SHA256 (RFC 8018). تنفيذ متزامن فوق `crypto`.
  /// يُخرِج [dkLen] بايت بدمج كتل بطول مخرَج SHA-256 (32 بايت).
  @visibleForTesting
  Uint8List pbkdf2(String password, Uint8List salt, int iterations, int dkLen) {
    final prf = Hmac(sha256, utf8.encode(password));
    final out = BytesBuilder();
    var block = 1;
    while (out.length < dkLen) {
      // U1 = HMAC(pw, salt || INT_BE32(block)); ثم Ui = HMAC(pw, Ui-1)؛ T = ⊕Ui.
      final seed = <int>[
        ...salt,
        (block >> 24) & 0xff,
        (block >> 16) & 0xff,
        (block >> 8) & 0xff,
        block & 0xff,
      ];
      var u = prf.convert(seed).bytes;
      final t = List<int>.from(u);
      for (var i = 1; i < iterations; i++) {
        u = prf.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      out.add(t);
      block++;
    }
    return Uint8List.fromList(out.toBytes().sublist(0, dkLen));
  }

  /// اشتقاق قديم (MDK1/MDK2): سلسلة SHA-256 مخصّصة. لا يُستخدم لنسخ جديدة.
  Uint8List _deriveKeyLegacy(String password, Uint8List salt) {
    var bytes = utf8.encode(password) + salt;
    var digest = sha256.convert(bytes).bytes;
    for (var i = 1; i < _legacyIterations; i++) {
      digest = sha256.convert(digest + salt).bytes;
    }
    return Uint8List.fromList(digest);
  }

  Uint8List _randomBytes(int n) {
    final key = enc.Key.fromSecureRandom(n);
    return key.bytes;
  }

  /// يشفّر [data] ويعيد حزمة بايتات قابلة للحفظ في ملف (الصيغة MDK3).
  /// التنسيق: MAGIC(4) | iterations(4 BE) | salt(16) | iv(16) | mac(32) | cipher
  Uint8List encryptBytes(Uint8List data, String password) {
    final salt = _randomBytes(16);
    final iv = enc.IV.fromSecureRandom(16);
    // 64 بايت: أول 32 لمفتاح التشفير، وآخر 32 لمفتاح المصادقة (مفتاحان مستقلّان).
    final master = pbkdf2(password, salt, _pbkdf2Iterations, 64);
    final encKey = Uint8List.fromList(master.sublist(0, 32));
    final macKey = Uint8List.fromList(master.sublist(32, 64));
    final encrypter =
        enc.Encrypter(enc.AES(enc.Key(encKey), mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(data, iv: iv);

    // مصادقة: HMAC-SHA256 على (salt|iv|ciphertext) بمفتاح مستقلّ
    // (encrypt-then-MAC) — يكشف أي تلاعب/تلف ويؤكّد صحّة كلمة المرور.
    final mac =
        Hmac(sha256, macKey).convert([...salt, ...iv.bytes, ...encrypted.bytes]);

    final iter = _pbkdf2Iterations;
    final builder = BytesBuilder();
    builder.add(utf8.encode(_magic3));
    builder.add([
      (iter >> 24) & 0xff,
      (iter >> 16) & 0xff,
      (iter >> 8) & 0xff,
      iter & 0xff,
    ]);
    builder.add(salt);
    builder.add(iv.bytes);
    builder.add(mac.bytes); // 32 بايت
    builder.add(encrypted.bytes);
    return builder.toBytes();
  }

  // مصادقة MDK2 القديمة: مفتاح المصادقة مشتقّ من مفتاح التشفير (يُبقى للقراءة).
  List<int> _hmacLegacy(
      List<int> encKey, List<int> salt, List<int> iv, List<int> cipher) {
    final macKey = sha256.convert([...encKey, ...utf8.encode('mac')]).bytes;
    return Hmac(sha256, macKey).convert([...salt, ...iv, ...cipher]).bytes;
  }

  /// مقارنة ثابتة الزمن (تفادي تسريب التوقيت).
  bool _ctEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// يفكّ تشفير حزمة أنشأها [encryptBytes]. يرمي استثناءً عند كلمة مرور خاطئة أو
  /// تلف/تلاعب (في الصيغة المصادَقة MDK2). يدعم الصيغة القديمة MDK1 للتوافق.
  Uint8List decryptBytes(Uint8List packed, String password) {
    final magic = utf8.decode(packed.sublist(0, 4));
    if (magic == _magic3) {
      // MDK3 (حاليّ): MAGIC | iterations(4) | salt(16) | iv(16) | mac(32) | cipher
      final iter = (packed[4] << 24) |
          (packed[5] << 16) |
          (packed[6] << 8) |
          packed[7];
      final salt = packed.sublist(8, 24);
      final ivBytes = packed.sublist(24, 40);
      final mac = packed.sublist(40, 72);
      final cipher = packed.sublist(72);
      final master = pbkdf2(password, Uint8List.fromList(salt), iter, 64);
      final encKey = Uint8List.fromList(master.sublist(0, 32));
      final macKey = Uint8List.fromList(master.sublist(32, 64));
      final expected =
          Hmac(sha256, macKey).convert([...salt, ...ivBytes, ...cipher]).bytes;
      if (!_ctEquals(mac, expected)) {
        throw const FormatException('النسخة تالفة أو كلمة المرور خاطئة');
      }
      final encrypter =
          enc.Encrypter(enc.AES(enc.Key(encKey), mode: enc.AESMode.cbc));
      return Uint8List.fromList(encrypter.decryptBytes(
          enc.Encrypted(Uint8List.fromList(cipher)),
          iv: enc.IV(Uint8List.fromList(ivBytes))));
    }
    if (magic == _magic2) {
      final salt = packed.sublist(4, 20);
      final ivBytes = packed.sublist(20, 36);
      final mac = packed.sublist(36, 68);
      final cipher = packed.sublist(68);
      final encKey = _deriveKeyLegacy(password, Uint8List.fromList(salt));
      final expected = _hmacLegacy(encKey, salt, ivBytes, cipher);
      if (!_ctEquals(mac, expected)) {
        throw const FormatException('النسخة تالفة أو كلمة المرور خاطئة');
      }
      final encrypter =
          enc.Encrypter(enc.AES(enc.Key(encKey), mode: enc.AESMode.cbc));
      return Uint8List.fromList(encrypter.decryptBytes(
          enc.Encrypted(Uint8List.fromList(cipher)),
          iv: enc.IV(Uint8List.fromList(ivBytes))));
    }
    if (magic == _magic) {
      // MDK1 (قديم، بلا مصادقة) — توافق رجعيّ مع النسخ السابقة.
      final salt = packed.sublist(4, 20);
      final iv = enc.IV(packed.sublist(20, 36));
      final cipher = packed.sublist(36);
      final key = enc.Key(_deriveKeyLegacy(password, Uint8List.fromList(salt)));
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return Uint8List.fromList(encrypter.decryptBytes(enc.Encrypted(cipher), iv: iv));
    }
    throw const FormatException('ملف النسخة الاحتياطية غير صالح');
  }

  /// تجزئة كلمة المرور/الرقم السري لتخزينه بأمان (للتحقق فقط).
  String hashSecret(String secret, String salt) {
    return sha256.convert(utf8.encode('$salt::$secret')).toString();
  }

  // ---------------------------------------------------------------------------
  // تشفير حقول قصيرة بمفتاح خام ثابت (لحقول كلمات المرور) — سريع.
  // التنسيق المُعاد (Base64): iv(16) | ciphertext
  // ---------------------------------------------------------------------------

  String encryptWithKey(String plain, Uint8List key) {
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plain, iv: iv);
    final packed = Uint8List.fromList(iv.bytes + encrypted.bytes);
    return base64Encode(packed);
  }

  String decryptWithKey(String packedBase64, Uint8List key) {
    if (packedBase64.isEmpty) return '';
    try {
      final packed = base64Decode(packedBase64);
      final iv = enc.IV(Uint8List.fromList(packed.sublist(0, 16)));
      final cipher = Uint8List.fromList(packed.sublist(16));
      final encrypter =
          enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.cbc));
      return encrypter.decrypt(enc.Encrypted(cipher), iv: iv);
    } catch (_) {
      return '';
    }
  }
}
