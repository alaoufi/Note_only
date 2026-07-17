// أداة ترخيص Alaoufi Notes — نظام UNI3 الموحّد (تعمل على جهازك أنت فقط).
//
// تنتج أكوادًا متوافقة تمامًا مع «مولّد أكواد التفعيل» وتطبيق الملاحظات:
// الكود = Base32( المدّة(2 بايت) + Ed25519_sign("UNI3|deviceId|duration") ).
//
// الاستخدام:
//   1) توليد زوج مفاتيح (مرة واحدة):
//        dart run tool/license.dart keygen
//      انسخ "PUBLIC KEY" إلى _publicKeyB64 في lib/services/license_service.dart،
//      واحتفظ بـ "PRIVATE KEY" سرًّا (لا تضعه في التطبيق إطلاقًا).
//
//   2) توليد رمز تفعيل لجهاز مستخدم (أرسل له الناتج):
//        dart run tool/license.dart sign <PRIVATE_KEY_B64> <DEVICE_ID> [DAYS]
//      DAYS اختياريّ: عدد أيام الصلاحية (0 أو حذفه = ترخيص دائم).
//
// المفتاح الخاص عندك وحدك → لا أحد يستطيع تزوير رموز، والرمز يعمل على جهاز واحد.

import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    _usage();
    return;
  }
  switch (args[0]) {
    case 'keygen':
      await _keygen();
      break;
    case 'sign':
      if (args.length < 3) {
        stderr.writeln('الاستخدام: sign <PRIVATE_KEY_B64> <DEVICE_ID> [DAYS]');
        exitCode = 2;
        return;
      }
      final days = args.length >= 4 ? (int.tryParse(args[3]) ?? 0) : 0;
      await _sign(args[1], args[2], days);
      break;
    default:
      _usage();
  }
}

void _usage() {
  print('''
أداة ترخيص Alaoufi Notes (نظام UNI3):
  dart run tool/license.dart keygen
  dart run tool/license.dart sign <PRIVATE_KEY_B64> <DEVICE_ID> [DAYS]
''');
}

Future<void> _keygen() async {
  final algo = Ed25519();
  final kp = await algo.newKeyPair();
  final priv = await kp.extractPrivateKeyBytes();
  final pub = (await kp.extractPublicKey()).bytes;
  print('=== احتفظ بهذا سرًّا (للتوقيع فقط) ===');
  print('PRIVATE KEY: ${base64Encode(priv)}');
  print('');
  print('=== ضع هذا في lib/services/license_service.dart (_publicKeyB64) ===');
  print('PUBLIC KEY: ${base64Encode(pub)}');
}

Future<void> _sign(String privB64, String deviceIdRaw, int days) async {
  // نطبّع رقم الجهاز كما يفعل التطبيق: أحرف كبيرة وحذف كل ما ليس [A-Z0-9].
  final deviceId =
      deviceIdRaw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  final duration = days < 0 ? 0 : (days & 0xffff); // أيام، 0 = دائم.
  final algo = Ed25519();
  final seed = _parseSeed(privB64); // يقبل hex(64) أو Base64 (متوافق مع حلالي).
  final kp = await algo.newKeyPairFromSeed(seed);
  // الرسالة الموقَّعة يجب أن تطابق التطبيق: "UNI3|deviceId|duration".
  final sig = await algo.sign(utf8.encode('UNI3|$deviceId|$duration'),
      keyPair: kp);
  final packet = <int>[(duration >> 8) & 0xff, duration & 0xff, ...sig.bytes];
  final code = _base32(packet);
  // تجميل في مجموعات من 5 أحرف (مثل عرض المولّد) — التطبيق يتجاهل الشرطات.
  final pretty = <String>[
    for (var i = 0; i < code.length; i += 5)
      code.substring(i, i + 5 > code.length ? code.length : i + 5)
  ].join('-');
  print('الجهاز: $deviceId');
  print('المدّة: ${duration == 0 ? 'دائم' : '$duration يوم'}');
  print('رمز التفعيل:');
  print(pretty);
}

// يقبل البذرة السرّية بصيغة hex (64 خانة — كما يُصدّرها مولّد «حلالي») أو Base64.
List<int> _parseSeed(String input) {
  final t = input.trim();
  final hex = t.toLowerCase().replaceAll(RegExp(r'[^0-9a-f]'), '');
  final looksHex = RegExp(r'^[0-9a-fA-F\s]+$').hasMatch(t) && hex.length == 64;
  if (looksHex) {
    return [
      for (var i = 0; i < 64; i += 2) int.parse(hex.substring(i, i + 2), radix: 16)
    ];
  }
  return base64Decode(t);
}

// Base32 (نفس أبجدية التطبيق، بلا أحرف ملتبسة I L O U).
const _b32 = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
String _base32(List<int> bytes) {
  var bits = 0, value = 0;
  final out = StringBuffer();
  for (final b in bytes) {
    value = (value << 8) | b;
    bits += 8;
    while (bits >= 5) {
      out.write(_b32[(value >> (bits - 5)) & 31]);
      bits -= 5;
    }
    value &= (1 << bits) - 1;
  }
  if (bits > 0) out.write(_b32[(value << (5 - bits)) & 31]);
  return out.toString();
}
