import 'package:flutter_test/flutter_test.dart';
import 'package:mudhakkarati/core/text/arabic_search.dart';

void main() {
  group('normalizeArabic', () {
    test('يوحّد الهمزات والألف', () {
      expect(normalizeArabic('أحمد'), normalizeArabic('احمد'));
      expect(normalizeArabic('إسلام'), 'اسلام');
      expect(normalizeArabic('آمنة'), 'امنه');
    });

    test('يُسقط التشكيل والتطويل', () {
      expect(normalizeArabic('كَتَبَ'), 'كتب');
      expect(normalizeArabic('مُحَمَّد'), 'محمد');
      expect(normalizeArabic('كتـــاب'), 'كتاب');
    });

    test('يوحّد التاء المربوطة والألف المقصورة', () {
      expect(normalizeArabic('مدرسة'), 'مدرسه');
      expect(normalizeArabic('مصطفى'), 'مصطفي');
    });

    test('يتجاهل «ال» التعريف في الكلمات الطويلة فقط', () {
      expect(normalizeArabic('الكتاب'), 'كتاب');
      expect(normalizeArabic('كتاب'), 'كتاب');
      // كلمة قصيرة: لا تُحذف «ال» تفاديًا للإفراط.
      expect(normalizeArabic('الم'), 'الم');
    });

    test('حروف لاتينية ⇒ حالة صغيرة', () {
      expect(normalizeArabic('Hello'), 'hello');
    });
  });

  group('findArabicMatches', () {
    test('يجد التطابق رغم اختلاف الهمزة', () {
      final m = findArabicMatches('قال أحمد', 'احمد');
      expect(m.length, 1);
      // النطاق يغطّي «أحمد» في النصّ الأصليّ.
      expect('قال أحمد'.substring(m[0][0], m[0][1]), 'أحمد');
    });

    test('يطابق «كتاب» داخل «الكتاب»', () {
      final m = findArabicMatches('قرأت الكتاب', 'كتاب');
      expect(m.length, 1);
      expect('قرأت الكتاب'.substring(m[0][0], m[0][1]), 'كتاب');
    });

    test('تطابقات متعددة غير متداخلة', () {
      final m = findArabicMatches('بيت بيت بيت', 'بيت');
      expect(m.length, 3);
    });

    test('لا تطابق ⇒ قائمة فارغة', () {
      expect(findArabicMatches('مرحبا', 'وداع'), isEmpty);
      expect(findArabicMatches('نص', ''), isEmpty);
    });
  });
}
