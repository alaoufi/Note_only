import 'dart:convert';

/// مرفق واحد ضمن قائمة مرفقات الملاحظة (صورة أو ملف PDF).
///
/// تُخزَّن القائمة كسلسلة JSON في عمود `attachments` بجدول الملاحظات، فيمكن
/// إضافة عدد مفتوح من الصور وملفات PDF لأي ملاحظة.
class NoteAttachment {
  /// المسار داخل مجلد المرفقات الخاص بالتطبيق.
  final String path;

  /// نوع المرفق: 'image' أو 'pdf'.
  final String kind;

  /// اسم أصلي اختياري للعرض (خاصّة لملفات PDF).
  final String? name;

  const NoteAttachment({required this.path, required this.kind, this.name});

  bool get isImage => kind == 'image';
  bool get isPdf => kind == 'pdf';

  Map<String, dynamic> toJson() => {
        'p': path,
        'k': kind,
        if (name != null) 'n': name,
      };

  factory NoteAttachment.fromJson(Map<String, dynamic> m) => NoteAttachment(
        path: (m['p'] ?? '') as String,
        kind: (m['k'] ?? 'image') as String,
        name: m['n'] as String?,
      );

  /// يرمّز القائمة إلى نص JSON للتخزين (فارغة ⇒ null كي لا تشغل مكانًا).
  static String? encode(List<NoteAttachment> list) =>
      list.isEmpty ? null : jsonEncode(list.map((e) => e.toJson()).toList());

  /// يفكّ القائمة من نص JSON (يتحمّل القيم التالفة بإرجاع قائمة فارغة).
  static List<NoteAttachment> decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final data = jsonDecode(raw);
      if (data is List) {
        return data
            .whereType<Map>()
            .map((m) => NoteAttachment.fromJson(m.cast<String, dynamic>()))
            .where((a) => a.path.isNotEmpty)
            .toList();
      }
    } catch (_) {
      // نص غير صالح — نتجاهله بأمان.
    }
    return const [];
  }
}
