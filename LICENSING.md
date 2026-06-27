# تفعيل التطبيق المربوط بالجهاز (Device-bound Activation)

حماية احترافية تعمل **دون إنترنت**: كل جهاز يحتاج رمز تفعيل موقّعًا منك،
والرمز يعمل على ذلك الجهاز فقط. نشر الـAPK لا يفيد أحدًا.

## الإعداد (مرة واحدة)

1. ولّد زوج مفاتيح على جهازك أنت (لا تفعلها في CI):

   ```
   cd mudhakkarati
   dart run tool/license.dart keygen
   ```

2. انسخ سطر `PUBLIC KEY` والصقه مكان `_publicKeyB64` في
   `lib/services/license_service.dart`.

3. **احتفظ بـ `PRIVATE KEY` سرًّا تمامًا** — لا تضعه في الكود أو على GitHub.
   به وحده تُولَّد الرموز؛ تسريبه يكسر الحماية.

> ملاحظة: قبل ضبط المفتاح العام يبقى التطبيق غير مقفول (وضع تطوير).

## تفعيل جهاز مستخدم

1. المستخدم يفتح التطبيق فيظهر **«رقم الجهاز»** ويرسله لك.
2. تولّد له الرمز (الصيغة العالمية UNIV1؛ `DAYS` اختياريّ، 0/حذفه = دائم):

   ```
   dart run tool/license.dart sign <PRIVATE_KEY_B64> <DEVICE_ID> [DAYS]
   ```
   أو استخدم تطبيق «مولّد أكواد التفعيل» مباشرةً (يدعم المدّة وكل تطبيقاتك).

3. ترسل له الرمز، فيلصقه في شاشة التفعيل ويعمل التطبيق على جهازه فقط.

> **إلغاء التفعيل (للاختبار):** الإعدادات ← الأمان ← «إلغاء التفعيل (للاختبار)»
> يمسح ترخيص هذا الجهاز فتظهر شاشة التفعيل عند إعادة الفتح.

## لماذا هذا آمن وعملي

- الرمز توقيع Ed25519 على رقم الجهاز؛ لا يُزوَّر بدون مفتاحك الخاص.
- الرمز مرتبط بجهاز واحد ⇒ عمليًّا «يُستخدم مرة».
- لا خادم ولا إنترنت — يناسب تطبيقًا أوفلاين بالكامل.

## الصيغة الدقيقة (المعادلة)

### كيف يُولّد التطبيق «رقم الجهاز» (الصيغة العالمية UNIV1)
```
raw      = ANDROID_ID            (أو identifierForVendor على iOS)
digest   = SHA-256( "alaoufi:" + raw )
deviceId = Base32( digest[0..9] )            # 10 بايت ⇒ 16 حرفًا
العرض    = تُجمَّع كل 4 أحرف بشرطة: XXXX-XXXX-XXXX-XXXX
```
أبجدية Base32 (بلا أحرف ملتبسة): `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`

### كيف تُولّد أنت رمز التفعيل (UNIV1، مع مدّة)
```
n        = رقم الجهاز بأحرف كبيرة بعد حذف كل ما ليس [A-Z0-9]
duration = أيام الصلاحية (0 = دائم)
sig      = Ed25519_Sign( PRIVATE_KEY , UTF8("UNIV1|" + n + "|" + duration) )   # 64 بايت
packet   = [ duration>>8 , duration&0xff , ...sig ]                            # 66 بايت
code     = Base32(packet)        # يُعرض بمجموعات من 5 أحرف بشرطات (تُتجاهَل)
```
الخوارزمية قياسية (RFC 8032) فتعمل بأي لغة. التطبيق يفكّ Base32، يقرأ المدّة من
أوّل بايتين، ثم يتحقّق من التوقيع على `UNIV1|deviceId|duration` بالمفتاح العام المدمج.

### مولّد بديل بلغة بايثون (UNIV1)
```python
# pip install pynacl
import sys
from nacl.signing import SigningKey
import base64 as b64

B32 = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
def base32(data):
    bits = val = 0; out = ""
    for byte in data:
        val = (val << 8) | byte; bits += 8
        while bits >= 5:
            out += B32[(val >> (bits - 5)) & 31]; bits -= 5
        val &= (1 << bits) - 1
    if bits: out += B32[(val << (5 - bits)) & 31]
    return out

priv_b64, device_id = sys.argv[1], sys.argv[2]
days = int(sys.argv[3]) if len(sys.argv) > 3 else 0
n = "".join(c for c in device_id.upper() if c.isalnum())
sk = SigningKey(b64.b64decode(priv_b64))                       # المفتاح الخاص (32 بايت)
sig = sk.sign(f"UNIV1|{n}|{days}".encode()).signature          # 64 بايت
print(base32(bytes([(days >> 8) & 255, days & 255]) + sig))    # رمز التفعيل
```
تشغيل: `python sign.py <PRIVATE_KEY_B64> <DEVICE_ID> [DAYS]`

