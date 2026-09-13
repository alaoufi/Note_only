import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/backup_service.dart';
import '../../services/movement_break_service.dart';
import '../../services/notification_service.dart';
import '../../services/review_service.dart';
import '../../services/sync/sync_service.dart';
import '../health/movement_break_screen.dart';
import '../editor/rich_text_field.dart';
import 'home_screen.dart';
import 'notes_provider.dart';

/// الجذر: يهيّئ البيانات ثم يعرض الصفحة الرئيسية (التي تحوي القائمة الجانبية).
///
/// يراقب دورة حياة التطبيق ليُجري **مزامنة سحابية تلقائية** عند الإقلاع وكلّما
/// عاد التطبيق إلى الواجهة (resume)، مع إظهار «تمت المزامنة ✓».
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> with WidgetsBindingObserver {
  bool _syncing = false;
  DateTime? _lastSyncDone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesProvider>().init();
      // إن أُقلع التطبيق من إشعار (فتح ملاحظة) ⇒ عالج الإطلاق.
      NotificationService.instance.handleLaunch();
      // شبكة أمان ضدّ فقدان الملاحظات: نُفعّل النسخ التلقائي اليومي افتراضيًا عند
      // أول تشغيل (مرّة واحدة)، ثم ننشئ نسخة إن حان موعدها — كلّه في الخلفية.
      BackupService.instance
          .ensureDefaultAutoBackup()
          .then((_) => BackupService.instance.maybeRunAutoBackup());
      // مزامنة أولى عند الإقلاع (تُعامَل كـ«فتح»).
      _autoSync(SyncTrigger.open);
      // أعِد عرض الملاحظات المثبّتة في الإشعارات (تختفي عند إغلاق التطبيق).
      _reassertPinnedNotes();
      // طلب تقييم لطيف بعد عدّة مرّات فتح (مرّة واحدة).
      ReviewService.maybeAsk();
      // تنبيه «لا تجلس طويلًا»: حمّل الإعداد ثم افحص إن كانت فترة حركة فعّالة الآن،
      // وواصل الفحص دوريًّا أثناء استخدام التطبيق.
      MovementBreakService.instance.load().then((_) {
        if (mounted) _checkMovementBreak();
      });
      _breakTimer =
          Timer.periodic(const Duration(seconds: 30), (_) => _checkMovementBreak());
    });
  }

  Timer? _breakTimer;
  bool _breakShowing = false;

  /// يعرض شاشة الحركة الكاملة إن كانت فترة فعّالة الآن (ولم تُعرض بعد).
  Future<void> _checkMovementBreak() async {
    if (_breakShowing || !mounted) return;
    final b = MovementBreakService.instance.activeBreakNow();
    if (b == null) return;
    _breakShowing = true;
    await Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => MovementBreakScreen(index: b.index, end: b.end),
    ));
    _breakShowing = false;
  }

  /// يعيد إظهار إشعارات الملاحظات المثبّتة بعد إعادة تشغيل التطبيق، ويُنظّف
  /// المثبّتة المحذوفة/المؤرشفة.
  Future<void> _reassertPinnedNotes() async {
    try {
      final svc = NotificationService.instance;
      final ids = await svc.pinnedIds();
      if (ids.isEmpty || !mounted) return;
      final repo = context.read<NotesProvider>().notes;
      for (final id in ids) {
        final note = await repo.getNote(id);
        if (note == null || note.isDeleted || note.isArchived) {
          await svc.cancelPinnedNote(id);
          continue;
        }
        await svc.showPinnedNote(id, note.title, richToPlainText(note.content));
      }
    } catch (_) {
      // لا يجب أن تُعطّل بدء التطبيق.
    }
  }

  @override
  void dispose() {
    _breakTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // «فتح» عند العودة للواجهة، و«إغلاق» عند ذهابها للخلفية — كلّ منهما يُطابَق
    // بالتردّد المختار في الإعدادات (كل فتح / عند الإغلاق / مرّة باليوم).
    if (state == AppLifecycleState.resumed) {
      _autoSync(SyncTrigger.open);
      _checkMovementBreak();
    } else if (state == AppLifecycleState.paused) {
      _autoSync(SyncTrigger.close);
    }
  }

  /// مزامنة تلقائية حسب التردّد المختار. تظهر بشريط خفيف ما لم يُفعّل وضع
  /// «المزامنة الصامتة» — وفي الحالين لا تُعطّل تفاعل المستخدم (عمل غير متزامن).
  Future<void> _autoSync(SyncTrigger trigger) async {
    if (_syncing) return;
    // تجنّب التكرار السريع عند تعدّد الأحداث خلال ثوانٍ.
    if (_lastSyncDone != null &&
        DateTime.now().difference(_lastSyncDone!) < const Duration(seconds: 8)) {
      return;
    }
    final svc = SyncService.instance;
    if (!await svc.shouldAutoSync(trigger)) return;
    final silent = await svc.silentSync();

    _syncing = true;
    if (!silent) {
      svc.status.value =
          const SyncStatus(SyncUi.syncing, 'جارٍ مزامنة ملاحظاتك…');
    }

    final r = await svc.syncNow();
    _lastSyncDone = DateTime.now();
    _syncing = false;

    // حدّث القائمة بهدوء عند النجاح.
    if (r.ok && mounted) {
      final notes = context.read<NotesProvider>();
      await notes.loadCategories();
      await notes.refresh();
    }

    if (silent) return; // الوضع الصامت: لا شريط ولا إشعار مرئيّ.

    svc.status.value = r.ok
        ? const SyncStatus(SyncUi.done, 'تمت المزامنة')
        : SyncStatus(SyncUi.error, r.message);
    // إخفاء الشريط تلقائيًا بعد لحظة.
    Future.delayed(Duration(seconds: r.ok ? 2 : 4), () {
      if (svc.status.value.state != SyncUi.syncing) {
        svc.status.value = const SyncStatus(SyncUi.idle);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const HomeScreen();
}
