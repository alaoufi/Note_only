/// بحث عربيّ ذكيّ: تطبيع يتجاهل اختلاف الهمزة والتشكيل و«ال» التعريف.
///
/// يُستعمل في مكانين:
/// 1) بحث القائمة الرئيسية (حصر الملاحظات المطابقة رغم اختلاف الهمزة/التشكيل).
/// 2) البحث داخل الملاحظة (تحديد مواضع التطابق والقفز إليها).
///
/// المطابقة غير حسّاسة لـ: الهمزات (أ إ آ ٱ ء ؤ ئ)، والألف المقصورة (ى)، والتاء
/// المربوطة (ة)، وعلامات التشكيل والتطويل، و«ال» التعريف في بداية الكلمات.
library;

/// علامات التشكيل والتطويل التي تُسقط تمامًا أثناء التطبيع.
const _diacritics = {
  'ً', // ً تنوين فتح
  'ٌ', // ٌ تنوين ضم
  'ٍ', // ٍ تنوين كسر
  'َ', // َ فتحة
  'ُ', // ُ ضمة
  'ِ', // ِ كسرة
  'ّ', // ّ شدّة
  'ْ', // ْ سكون
  'ٓ', // ٓ مدّة
  'ٔ', // ٔ همزة علوية
  'ٕ', // ٕ همزة سفلية
  'ٖ', 'ٗ', '٘', 'ٙ', 'ٚ', 'ٛ', 'ٜ',
  'ٝ', 'ٞ', 'ٟ',
  'ٰ', // ٰ ألف خنجرية
  'ـ', // ـ تطويل
};

/// تطبيع حرف واحد ⇒ قد يعيد حرفًا أو سلسلة فارغة (إسقاط).
String _mapChar(String c) {
  switch (c) {
    case 'أ':
    case 'إ':
    case 'آ':
    case 'ٱ':
    case 'ٲ':
    case 'ٳ':
      return 'ا';
    case 'ى':
      return 'ي';
    case 'ئ':
      return 'ي';
    case 'ؤ':
      return 'و';
    case 'ة':
      return 'ه';
    case 'ء':
      return ''; // إسقاط الهمزة المفردة
    default:
      if (_diacritics.contains(c)) return '';
      return c.toLowerCase();
  }
}

final _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);
bool _isLetter(String c) => _letterOrDigit.hasMatch(c);

/// يطبّع [s] مع بناء خريطة [map]: `map[i]` = موضع الحرف المطبَّع رقم i في النصّ
/// الأصليّ. تُستعمل الخريطة لإرجاع مواضع التطابق إلى إحداثيات النصّ الأصليّ.
(String, List<int>) _normalizeWithMap(String s) {
  final sb = StringBuffer();
  final map = <int>[];
  final n = s.length;
  var i = 0;
  var atWordStart = true;
  while (i < n) {
    final ch = s[i];
    if (!_isLetter(ch)) {
      // فاصل (مسافة/ترقيم/سطر): يمرّ مطبَّعًا ويعيد ضبط «بداية الكلمة».
      final m = _mapChar(ch);
      for (var k = 0; k < m.length; k++) {
        sb.write(m[k]);
        map.add(i);
      }
      atWordStart = true;
      i++;
      continue;
    }
    // «ال» التعريف في بداية كلمة تليها حرفان فأكثر ⇒ تُتجاهَل (كي يتطابق
    // «كتاب» مع «الكتاب»). لا نتجاهلها في الكلمات القصيرة (مثل «الم») تفاديًا
    // للإفراط في الحذف.
    if (atWordStart &&
        (ch == 'ا' || ch == 'أ' || ch == 'إ' || ch == 'آ' || ch == 'ٱ') &&
        i + 1 < n &&
        s[i + 1] == 'ل' &&
        _remainingWordLetters(s, i + 2) >= 2) {
      i += 2; // تجاهُل الألف واللام (لا تُضاف للخريطة).
      atWordStart = false;
      continue;
    }
    final m = _mapChar(ch);
    for (var k = 0; k < m.length; k++) {
      sb.write(m[k]);
      map.add(i);
    }
    atWordStart = false;
    i++;
  }
  return (sb.toString(), map);
}

/// عدد حروف الكلمة المتبقّية ابتداءً من [from] (حتى أول فاصل).
int _remainingWordLetters(String s, int from) {
  var count = 0;
  for (var i = from; i < s.length && _isLetter(s[i]); i++) {
    count++;
  }
  return count;
}

/// النصّ المطبَّع فقط (للبحث المنطقيّ «يحتوي» في القائمة الرئيسية).
String normalizeArabic(String s) => _normalizeWithMap(s).$1;

/// مواضع تطابق [needle] داخل [haystack] كأزواج `[start, end]` بإحداثيات النصّ
/// الأصليّ (بحث ذكيّ: همزة/تشكيل/«ال»). غير متداخلة، مرتّبة تصاعديًّا.
List<List<int>> findArabicMatches(String haystack, String needle) {
  final nn = normalizeArabic(needle);
  if (nn.isEmpty) return const [];
  final (nh, map) = _normalizeWithMap(haystack);
  if (nh.isEmpty) return const [];
  final out = <List<int>>[];
  var i = nh.indexOf(nn);
  while (i != -1) {
    final start = map[i];
    final endNorm = i + nn.length;
    final end = endNorm < map.length ? map[endNorm] : haystack.length;
    out.add([start, end]);
    i = nh.indexOf(nn, endNorm);
  }
  return out;
}
