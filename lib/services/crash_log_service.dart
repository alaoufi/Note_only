import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// سجلّ أعطال محليّ بسيط — يحفظ أخطاء التشغيل في ملفّ على الجهاز يستطيع المستخدم
/// عرضه ومشاركته مع المطوّر. لا إنترنت، ولا تتبّع، ولا بيانات شخصية: أخطاء فقط.
///
/// آمن للاستدعاء من معالِجات الأخطاء المتزامنة (FlutterError.onError): بعد
/// [init] تُكتب الأسطر تزامنيًّا (append) بحجم محدود؛ وقبل [init] تُخزَّن مؤقّتًا
/// في الذاكرة ثم تُفرَّغ عند التهيئة.
class CrashLogService {
  CrashLogService._();
  static final CrashLogService instance = CrashLogService._();

  static const _fileName = 'crash_log.txt';
  static const _maxBytes = 256 * 1024; // سقف حجم السجلّ (نُبقي الأحدث).

  File? _file;
  final List<String> _pending = [];

  /// يهيّئ مسار الملفّ ويُفرّغ ما تجمّع قبل التهيئة. لا يرمي أبدًا.
  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/$_fileName');
      if (_pending.isNotEmpty) {
        for (final line in _pending) {
          _appendSync(line);
        }
        _pending.clear();
      }
    } catch (_) {/* لا نُعطّل التطبيق لأجل السجلّ */}
  }

  /// يسجّل خطأً (وسم + الخطأ + أثر المكدّس اختياريًّا). آمن ومتزامن.
  void log(String tag, Object error, [StackTrace? stack]) {
    final ts = DateTime.now().toIso8601String();
    final buf = StringBuffer('[$ts] $tag: $error');
    if (stack != null) {
      final s = stack.toString().split('\n').take(8).join('\n');
      if (s.trim().isNotEmpty) buf.write('\n$s');
    }
    final line = '${buf.toString()}\n';
    if (_file == null) {
      // قبل التهيئة: احتفظ بآخر 100 سطر في الذاكرة فقط.
      _pending.add(line);
      if (_pending.length > 100) _pending.removeAt(0);
    } else {
      _appendSync(line);
    }
  }

  void _appendSync(String line) {
    try {
      _file!.writeAsStringSync(line, mode: FileMode.append, flush: false);
      _trimIfNeeded();
    } catch (_) {/* تجاهل فشل الكتابة */}
  }

  /// يقصّ الملفّ إلى النصف عند تجاوز السقف (نُبقي الأحدث).
  void _trimIfNeeded() {
    try {
      final f = _file;
      if (f == null || !f.existsSync()) return;
      if (f.lengthSync() <= _maxBytes) return;
      final content = f.readAsStringSync();
      final keep = content.substring(content.length ~/ 2);
      f.writeAsStringSync('…(قُصّ السجلّ)\n$keep', flush: true);
    } catch (_) {}
  }

  /// نصّ السجلّ الحاليّ (فارغ إن لم يوجد).
  Future<String> read() async {
    try {
      final f = _file ?? File('${(await getApplicationDocumentsDirectory()).path}/$_fileName');
      if (!await f.exists()) return '';
      return await f.readAsString();
    } catch (_) {
      return '';
    }
  }

  /// هل يوجد سجلّ غير فارغ؟
  Future<bool> hasContent() async => (await read()).trim().isNotEmpty;

  /// يمسح السجلّ.
  Future<void> clear() async {
    try {
      final f = _file;
      if (f != null && await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// يشارك ملفّ السجلّ (لإرساله للمطوّر).
  Future<void> share() async {
    try {
      final f = _file ?? File('${(await getApplicationDocumentsDirectory()).path}/$_fileName');
      if (!await f.exists()) return;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(f.path, mimeType: 'text/plain')],
        subject: 'سجلّ أعطال — مذكراتي',
      ));
    } catch (_) {}
  }
}
