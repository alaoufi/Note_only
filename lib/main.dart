import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/database/app_database.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/note_repository.dart';
import 'features/editor/note_editor_screen.dart';
import 'features/home/notes_provider.dart';
import 'features/settings/settings_provider.dart';
import 'features/subscription/subscription_service.dart';
import 'services/ai_service.dart';
import 'services/crash_log_service.dart';
import 'services/notification_service.dart';
import 'services/vault_service.dart';

/// أخطاء التهيئة (إن وُجدت) — لا تمنع إقلاع التطبيق، وتُعرض للمستخدم عند الطلب.
final List<String> startupErrors = [];

/// تنفّذ خطوة تهيئة بأمان: أي فشل يُسجَّل ولا يُعطّل التطبيق.
Future<void> _safe(String name, Future<void> Function() step) async {
  try {
    await step();
  } catch (e, st) {
    startupErrors.add('$name: $e');
    CrashLogService.instance.log('init:$name', e, st);
  }
}

Future<void> main() async {
  // هل أقلع التطبيق فعلًا؟ بعد الإقلاع لا نهدم الواجهة الحيّة بسبب خطأ غير
  // متوقّع أثناء الاستخدام (نكتفي بتسجيله) — وإلا يفقد المستخدم شاشته بالكامل.
  var appStarted = false;
  // نلتقط أي خطأ غير متوقع بدل أن يتعطّل التطبيق بصمت.
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // سقف صارم لذاكرة الصور: يمنع تراكم الصور المفكوكة في الـ RAM (سبب رئيسي
    // لبطء الجهاز وتعليقه). القيم الافتراضية (1000 صورة/100م.ب) عالية جدًّا مع
    // صور الكاميرا. نُبقيها ضمن حدود آمنة.
    PaintingBinding.instance.imageCache.maximumSizeBytes = 48 << 20; // ‎48MB
    PaintingBinding.instance.imageCache.maximumSize = 60; // ‎60 صورة كحد أقصى

    FlutterError.onError = (details) {
      startupErrors.add('FlutterError: ${details.exceptionAsString()}');
      CrashLogService.instance.log('FlutterError', details.exception, details.stack);
    };

    // بدل شاشة رمادية/انهيار عند فشل بناء أي واجهة، نعرض نص الخطأ ليُصوَّر.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Material(
          color: Colors.white,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚠️ خطأ في الواجهة — صوّر هذه الرسالة وأرسلها:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 8),
                  SelectableText('${details.exception}',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      );
    };

    // تهيئة بيانات التواريخ (للتقويم بالعربية والإنجليزية).
    await _safe('dates', () async {
      await initializeDateFormatting('ar');
      await initializeDateFormatting('en');
    });

    // سجلّ الأعطال المحليّ (يهيّئ مسار الملفّ ويُفرّغ ما تجمّع قبل التهيئة).
    await _safe('crashlog', () => CrashLogService.instance.init());

    // مفتاح تشفير كلمات المرور (قد يفشل على بعض الأجهزة — لا يجب أن يُعطّل التطبيق).
    await _safe('vault', () => VaultService.instance.ensureKey());

    // إعداد مساعد الذكاء الاصطناعي (يُقرأ من التخزين الآمن — لا يُعطّل الإقلاع).
    await _safe('ai', () => AiService.instance.init());

    // الإشعارات/المنبّه المحلي.
    await _safe('notifications', () async {
      await NotificationService.instance.init();
      await NotificationService.instance.requestPermissions();
      // فتح الملاحظة عند الضغط على إشعار مرتبط بها.
      NotificationService.instance.onOpenNote = (noteId) {
        appNavigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: noteId)),
        );
      };
    });

    final db = AppDatabase.instance;
    final noteRepo = NoteRepository(db);
    final categoryRepo = CategoryRepository(db);

    final settings = SettingsProvider();
    await _safe('settings', () => settings.load());

    final notesProvider = NotesProvider(noteRepo, categoryRepo);

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: notesProvider),
          ChangeNotifierProvider.value(value: SubscriptionService.instance),
        ],
        child: const MudhakkaratiApp(),
      ),
    );
    appStarted = true;
  }, (error, stack) {
    startupErrors.add('Uncaught: $error');
    CrashLogService.instance.log('Uncaught', error, stack);
    // إن تعطّل **قبل** عرض أي شيء، نعرض شاشة الخطأ بدل توقّف التطبيق. أمّا بعد
    // الإقلاع فلا نهدم الواجهة الحيّة بسبب خطأ غير متوقّع في إجراء واحد (نسجّله
    // فقط) كي لا يفقد المستخدم شاشته بالكامل.
    if (!appStarted) {
      runApp(_StartupErrorApp(error: '$error\n\n$stack'));
    }
  });
}

/// شاشة احتياطية تعرض الخطأ بدل أن «يتوقف التطبيق» دون معلومة.
class _StartupErrorApp extends StatelessWidget {
  final String error;
  const _StartupErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('تعذّر بدء التطبيق')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('حدث خطأ أثناء الإقلاع. صوّر هذه الرسالة وأرسلها للمطوّر:'),
                const SizedBox(height: 12),
                SelectableText(error,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
