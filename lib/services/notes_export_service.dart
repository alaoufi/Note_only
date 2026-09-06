import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models/enums.dart';
import '../data/models/note.dart';
import '../features/editor/rich_text_field.dart' show richToPlainText;

/// تصدير الملاحظات: تحديد متعدّد ⇒ ملفّ Markdown واحد، أو تصدير الكلّ ⇒ أرشيف
/// ZIP يحوي ملفّ Markdown لكلّ ملاحظة + ملفّ JSON للنسخ/النقل. محليّ بالكامل.
class NotesExportService {
  NotesExportService._();
  static final NotesExportService instance = NotesExportService._();

  /// يصدّر [selected] كملفّ Markdown واحد ويفتح ورقة المشاركة.
  Future<void> exportSelectionMarkdown(List<Note> selected) async {
    final buf = StringBuffer();
    for (var i = 0; i < selected.length; i++) {
      buf.write(_noteToMarkdown(selected[i]));
      if (i < selected.length - 1) buf.writeln('\n\n---\n');
    }
    final dir = await getTemporaryDirectory();
    final name = 'ملاحظات_${_stamp()}.md';
    final file = File('${dir.path}/$name');
    await file.writeAsString(buf.toString(), flush: true);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'text/markdown')],
      subject: 'تصدير ملاحظات (${selected.length})',
    ));
  }

  /// يصدّر كلّ [all] كأرشيف ZIP: ملفّ .md لكلّ ملاحظة + notes.json.
  Future<void> exportAllArchive(List<Note> all) async {
    final archive = Archive();
    final used = <String>{};
    for (final n in all) {
      var base = _safeName(n.title.trim().isEmpty ? 'ملاحظة_${n.id ?? ''}' : n.title.trim());
      var name = '$base.md';
      var k = 2;
      while (used.contains(name)) {
        name = '${base}_$k.md';
        k++;
      }
      used.add(name);
      final bytes = utf8.encode(_noteToMarkdown(n));
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }
    // ملفّ JSON بنيويّ للنقل/النسخ.
    final jsonBytes = utf8.encode(
        const JsonEncoder.withIndent('  ').convert(all.map(_noteToJson).toList()));
    archive.addFile(ArchiveFile('notes.json', jsonBytes.length, jsonBytes));

    final zip = ZipEncoder().encode(archive);
    if (zip == null) throw Exception('فشل ضغط الأرشيف');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/كل_الملاحظات_${_stamp()}.zip');
    await file.writeAsBytes(zip, flush: true);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/zip')],
      subject: 'تصدير كل الملاحظات (${all.length})',
    ));
  }

  // ---- تحويلات ----

  String _noteToMarkdown(Note n) {
    final title = n.title.trim().isEmpty ? 'بدون عنوان' : n.title.trim();
    final buf = StringBuffer('# $title\n\n')
      ..writeln('_${_fmtDate(n.updatedAt)}_\n');
    switch (n.type) {
      case NoteType.password:
      case NoteType.treatment:
        buf.writeln('> (محتوى منظَّم — لم يُصدَّر لأسباب الخصوصية)');
        break;
      default:
        final body = richToPlainText(n.content).trim();
        buf.writeln(body.isEmpty ? '_(فارغة)_' : body);
    }
    return buf.toString();
  }

  Map<String, dynamic> _noteToJson(Note n) => {
        'id': n.id,
        'uuid': n.uuid,
        'title': n.title,
        'type': n.type.name,
        // كلمات المرور/العلاج محتواها منظَّم وحسّاس ⇒ لا نُصدّر متنها.
        'content': (n.type == NoteType.password || n.type == NoteType.treatment)
            ? ''
            : richToPlainText(n.content),
        'categoryId': n.categoryId,
        'isPinned': n.isPinned,
        'isFavorite': n.isFavorite,
        'tags': n.tags,
        'createdAt': n.createdAt.toIso8601String(),
        'updatedAt': n.updatedAt.toIso8601String(),
      };

  String _fmtDate(DateTime d) {
    String two(int x) => x.toString().padLeft(2, '0');
    return '${d.year}/${two(d.month)}/${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  String _stamp() {
    final d = DateTime.now();
    String two(int x) => x.toString().padLeft(2, '0');
    return '${d.year}${two(d.month)}${two(d.day)}_${two(d.hour)}${two(d.minute)}';
  }

  String _safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|\n\r\t]'), ' ').trim();
    final limited = cleaned.length > 50 ? cleaned.substring(0, 50) : cleaned;
    return limited.isEmpty ? 'ملاحظة' : limited;
  }
}
