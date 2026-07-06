import 'dart:convert';

/// بيانات ملاحظة العلاج/الدواء (حقول منظّمة) — تُخزَّن في `content` كـ JSON.
/// غير مشفّرة (ليست سرّية)، فتعمل معها الفهرسة والبحث مباشرةً.
class TreatmentEntry {
  final String section; // القسم (يُرتَّب عليه)
  final String brandName; // اسم العلاج التجاري
  final String activeIngredient; // المادة الفعّالة
  final String concentration; // التركيز
  final String dose; // الجرعة
  final String usage; // طريقة الاستخدام
  final String duration; // مدة الاستخدام
  final String cautions; // المحاذير
  final String sideEffects; // الآثار الجانبية
  final String notes; // ملاحظات

  const TreatmentEntry({
    this.section = '',
    this.brandName = '',
    this.activeIngredient = '',
    this.concentration = '',
    this.dose = '',
    this.usage = '',
    this.duration = '',
    this.cautions = '',
    this.sideEffects = '',
    this.notes = '',
  });

  TreatmentEntry copyWith({
    String? section,
    String? brandName,
    String? activeIngredient,
    String? concentration,
    String? dose,
    String? usage,
    String? duration,
    String? cautions,
    String? sideEffects,
    String? notes,
  }) {
    return TreatmentEntry(
      section: section ?? this.section,
      brandName: brandName ?? this.brandName,
      activeIngredient: activeIngredient ?? this.activeIngredient,
      concentration: concentration ?? this.concentration,
      dose: dose ?? this.dose,
      usage: usage ?? this.usage,
      duration: duration ?? this.duration,
      cautions: cautions ?? this.cautions,
      sideEffects: sideEffects ?? this.sideEffects,
      notes: notes ?? this.notes,
    );
  }

  String toStoredJson() => jsonEncode({
        'section': section,
        'brand': brandName,
        'active': activeIngredient,
        'concentration': concentration,
        'dose': dose,
        'usage': usage,
        'duration': duration,
        'cautions': cautions,
        'side_effects': sideEffects,
        'notes': notes,
      });

  factory TreatmentEntry.fromStoredJson(String raw) {
    if (raw.trim().isEmpty) return const TreatmentEntry();
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      String g(String k) => (m[k] as String?) ?? '';
      return TreatmentEntry(
        section: g('section'),
        brandName: g('brand'),
        activeIngredient: g('active'),
        concentration: g('concentration'),
        dose: g('dose'),
        usage: g('usage'),
        duration: g('duration'),
        cautions: g('cautions'),
        sideEffects: g('side_effects'),
        notes: g('notes'),
      );
    } catch (_) {
      return const TreatmentEntry();
    }
  }

  /// عنوان مختصر للبطاقة/القائمة.
  String get displayTitle {
    if (brandName.trim().isNotEmpty) return brandName;
    if (activeIngredient.trim().isNotEmpty) return activeIngredient;
    if (section.trim().isNotEmpty) return section;
    return 'علاج';
  }

  /// القسم للعرض/الترتيب (أو «غير مصنّف»).
  String get sectionLabel =>
      section.trim().isEmpty ? 'غير مصنّف' : section.trim();

  /// نصّ قابل للبحث (كل الحقول).
  static String searchableFromJson(String raw) {
    if (raw.trim().isEmpty) return '';
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.values.whereType<String>().join(' ');
    } catch (_) {
      return '';
    }
  }

  static String titleFromJson(String raw) =>
      TreatmentEntry.fromStoredJson(raw).displayTitle;

  bool get isEmpty =>
      section.trim().isEmpty &&
      brandName.trim().isEmpty &&
      activeIngredient.trim().isEmpty &&
      concentration.trim().isEmpty &&
      dose.trim().isEmpty &&
      usage.trim().isEmpty &&
      duration.trim().isEmpty &&
      cautions.trim().isEmpty &&
      sideEffects.trim().isEmpty &&
      notes.trim().isEmpty;
}
