import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

import 'core/l10n/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/security/activation_gate.dart';
import 'features/security/app_lock_gate.dart';
import 'features/settings/settings_provider.dart';
import 'features/subscription/subscription_gate.dart';
import 'services/memory_housekeeping.dart';
import 'services/notification_service.dart';

/// اختيار نظام الترخيص وقت البناء:
///   نسخة Google Play  ⇐ اشتراكات مدفوعة  (ابنِ بـ: --dart-define=STORE_BILLING=true)
///   نسخة جانبية        ⇐ تفعيل بمفتاح (keygen) الافتراضي.
const bool kStoreBilling =
    bool.fromEnvironment('STORE_BILLING', defaultValue: false);

class MudhakkaratiApp extends StatefulWidget {
  const MudhakkaratiApp({super.key});

  @override
  State<MudhakkaratiApp> createState() => _MudhakkaratiAppState();
}

class _MudhakkaratiAppState extends State<MudhakkaratiApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // عند خروج المستخدم/تعطيل التطبيق ننظّف الذاكرة والملفات المؤقّتة بعمق
    // (دون المساس بالمرفقات أو القاعدة) — يمنع تراكمها والتهامها موارد الجهاز.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      MemoryHousekeeping.instance.deepClean();
    }
  }

  @override
  void didHaveMemoryPressure() {
    // النظام يحذّر من نقص الذاكرة — نفرّغ ذاكرة الصور فورًا.
    MemoryHousekeeping.instance.clearRuntimeCaches();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    // عند تفعيل «ألوان النظام» نلتقط لوحة الجهاز (أندرويد 12+) ونمرّرها للثيم؛
    // وإلا (أو إن لم تتوفّر) نرجع للون البذرة تلقائيًّا.
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final useDynamic = settings.dynamicColor;
        final lightScheme = useDynamic ? lightDynamic?.harmonized() : null;
        final darkScheme = useDynamic ? darkDynamic?.harmonized() : null;
        return MaterialApp(
          title: 'Notes',
          navigatorKey: appNavigatorKey,
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: AppTheme.light(settings.seedColor, settings.fontScale,
              settings.fontFamily, lightScheme),
          darkTheme: AppTheme.dark(settings.seedColor, settings.fontScale,
              settings.fontFamily, darkScheme),
          locale: settings.locale,
          supportedLocales: S.supportedLocales,
          localizationsDelegates: const [
            SDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          // ملاحظة: FlutterQuillLocalizations.delegate ثابت (const) لذا تبقى القائمة const.
          // ضمان اتجاه RTL للعربية.
          builder: (context, child) {
            final isRtl = S.rtlLanguages.contains(settings.locale.languageCode);
            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            );
          },
          home: kStoreBilling
              ? const SubscriptionGate(child: AppLockGate())
              : const ActivationGate(child: AppLockGate()),
        );
      },
    );
  }
}
