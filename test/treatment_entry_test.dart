import 'package:flutter_test/flutter_test.dart';
import 'package:mudhakkarati/data/models/treatment_entry.dart';

void main() {
  group('TreatmentEntry', () {
    test('round-trip لكل الحقول', () {
      const e = TreatmentEntry(
        section: 'مسكنات',
        brandName: 'بنادول',
        activeIngredient: 'باراسيتامول',
        concentration: '500mg',
        dose: 'قرص',
        usage: 'بعد الأكل',
        duration: '3 أيام',
        cautions: 'الكبد',
        sideEffects: 'غثيان',
        notes: 'ملاحظة',
      );
      final back = TreatmentEntry.fromStoredJson(e.toStoredJson());
      expect(back.section, 'مسكنات');
      expect(back.brandName, 'بنادول');
      expect(back.activeIngredient, 'باراسيتامول');
      expect(back.concentration, '500mg');
      expect(back.sideEffects, 'غثيان');
      expect(back.notes, 'ملاحظة');
    });

    test('displayTitle و sectionLabel و isEmpty', () {
      expect(const TreatmentEntry().isEmpty, isTrue);
      expect(const TreatmentEntry(brandName: 'x').isEmpty, isFalse);
      expect(const TreatmentEntry(activeIngredient: 'a').displayTitle, 'a');
      expect(const TreatmentEntry(brandName: 'B', activeIngredient: 'a')
          .displayTitle, 'B');
      expect(const TreatmentEntry().sectionLabel, 'غير مصنّف');
      expect(const TreatmentEntry(section: 'مضادات').sectionLabel, 'مضادات');
    });

    test('searchableFromJson يجمع الحقول', () {
      const e = TreatmentEntry(brandName: 'بنادول', activeIngredient: 'بارا');
      final s = TreatmentEntry.searchableFromJson(e.toStoredJson());
      expect(s.contains('بنادول'), isTrue);
      expect(s.contains('بارا'), isTrue);
    });
  });
}
