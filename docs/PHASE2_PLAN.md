# المرحلة ٢ — خطة التخصيص لتطبيق «ملاحظات» فقط

> ## ✅ الحالة: المرحلة ٢ منفّذة ومُتحقَّقة
> أُزيلت الميزات (التقويم، التذكيرات، الأدوية، النغمات) مع كل ربطها، وحُذف
> الكود الميّت في طبقة الخدمات، وأُسقطت حزمة `table_calendar` و8.1MB من أصول
> الصوت. **`flutter analyze`: ٠ أخطاء/تحذيرات، و`flutter test`: كل الاختبارات تنجح**
> (على Flutter 3.44.4 / Dart 3.12.2).
>
> **أُبقِيَ عمدًا (بنية تحتية ما زالت الملاحظات تحتاجها):** `NotificationService`
> (يوفّر `appNavigatorKey`، الملاحظات المثبّتة، الأذونات، فتح ملاحظة من إشعار)،
> نموذج `Reminder` و`ReminderRepository` (يستخدمهما النسخ الاحتياطي لحفظ/استعادة
> جدول التذكيرات القديم)، و`med_occurrences` (يعتمد عليه `NotificationService`).
> أُبقِيَت ميزتا «الملخّص الأسبوعي» و«التنظيف» لأنهما تعتمدان على الملاحظات فقط
> ولم تردا في قائمة الإزالة بـ`APP_GUIDE`.
>
> **متبقٍّ اختياريّ (غير حاجز):** تنظيف مفاتيح l10n غير المستخدمة (نغمة/تذكير/
> دواء/تقويم)؛ مراجعة `speech_to_text`/`signature` (بلا استيراد في Dart)؛ أصوات
> `android/.../res/raw` الخام؛ وإسقاط جداول `reminders`/`med_doses` عبر ترقية
> جديدة (تُرِكت لئلّا تكسر قواعد المستخدمين الحاليّة — انظر القسم ٦).

خطة تنفيذ دقيقة لإزالة الميزات غير المتعلّقة بالملاحظات (التذكيرات، الأدوية،
التقويم، النغمات، وما يتبعها)، مع إبقاء التطبيق قابلًا للبناء في كل خطوة.

> **بوّابة الجودة:** هذا التغيير يكسر كل `import`/`switch`/مرجع يشير إلى الميزة
> المحذوفة. نفّذ كل خطوة ثم شغّل **`flutter analyze`** (المُصرِّف يدلّك على البقايا)،
> و**`flutter test`** قبل أي التزام. لا تدفع تغييرًا لا يبني.
>
> هذه الخطة كُتبت في بيئة **بلا Flutter** (مراجعة ثابتة)، لذا تحقّق بالمُصرِّف عند التنفيذ.

---

## 0) تمييز مهمّ قبل البدء

«تذكير» في هذا الكود يعني شيئين مختلفين — لا تخلط بينهما:

| المعنى | أمثلة في الكود | القرار |
|---|---|---|
| **ميزة التذكيرات/المنبّه** (للحذف) | `RemindersProvider`، `RemindersScreen`، `reminder_dialog`، `AlarmScreen`، `noteHasReminder`، `alarmTone` | تُزال |
| **تذكير تصدير النسخة الاحتياطية** (يُبقى) | `_showBackupReminder`، `_backupReminderChecked`، `needsExternalBackupReminder()` | **يبقى** — لا علاقة له بميزة التذكيرات |

كذلك **`NotificationService` يبقى**: ما زال مطلوبًا للموجز/إشعارات النسخ
الاحتياطي والتحديث الذاتيّ. نزيل منه فقط ما يخصّ جدولة تذكيرات الملاحظات والمنبّه.

---

## 1) قرار التصميم: زرّ التذكير في الملاحظة

`note_actions.dart` و`note_editor_screen.dart` يعرضان زرّ «تذكير» يفتح
`showReminderDialog`. اختر أحد مسارين:

- **(أ) إزالة كاملة** (موصى به للتخصيص): احذف الزرّ والحوار وكل ميزة التذكيرات.
- **(ب) تذكير بسيط**: أبقِ إشعارًا واحدًا لكل ملاحظة بلا شاشات التذكيرات الكاملة
  (تكرار/أهميّة/منبّه). يتطلّب إبقاء جزء صغير من `NotificationService` و`Reminder`.

بقيّة الخطة تفترض **المسار (أ)**. للمسار (ب) أبقِ `reminder_dialog.dart` مبسّطًا
وتجاهل خطوات حذفه.

---

## 2) ترتيب التنفيذ (من الأوراق نحو الجذور)

ابدأ بإزالة *الاستخدامات* ثم احذف الملفات، كي يبقى المُصرِّف مفيدًا:

### الخطوة أ — نقاط التنقّل (الأسهل أولًا)
- `lib/widgets/app_drawer.dart:7,133` — أزِل مدخل `CleanupScreen` (واستيراده).
- `lib/features/home/home_screen.dart`
  - أزِل الاستيرادات: `calendar/calendar_screen.dart` (سطر 19)،
    `insights/weekly_summary_screen.dart` (21)، `reminders/reminders_provider.dart`
    (22)، `reminders/reminders_screen.dart` (23).
  - أزِل مدخل القائمة `weekly_summary` (≈445) وأي زرّ تقويم/تذكيرات.
  - **أبقِ** منطق `_maybeShowBackupReminder`/`_showBackupReminder` (تذكير النسخ).
  - أزِل استدعاءات `RemindersProvider.refresh()/ensureScheduled()` (≈142,144).
- `lib/features/settings/settings_screen.dart`
  - أزِل استيراد `reminders/reminders_screen.dart` (19) ومدخل `RemindersScreen` (≈712).
  - أزِل قسم «الإنذار/النغمة» (`alarmTone`، `sound_options`، ≈669‑753) ومنتقي النغمات.

### الخطوة ب — البطاقة والإجراءات
- `lib/widgets/note_card.dart` — أزِل شارة `Icons.alarm` المرتبطة بـ
  `noteHasReminder` (≈92‑97).
- `lib/widgets/note_actions.dart` — أزِل استيراد `reminder_dialog.dart` (13)
  وبند «تذكير» (`tile(Icons.alarm, …)`، ≈119‑121).
- `lib/features/editor/note_editor_screen.dart` — أزِل زرّ التذكير
  (`Icons.alarm` → `showReminderDialog`) واستيراد `reminders/reminder_dialog.dart`.

### الخطوة ج — المزوّد العام والإقلاع
- `lib/features/home/notes_provider.dart` — أزِل `_reminderNoteIds`،
  `noteHasReminder()` (89‑90)، والسطر 178 (`noteIdsWithReminders()`).
- `lib/features/home/root_screen.dart` — أزِل استدعاءات
  `RemindersProvider.refresh()` (34) و`ensureScheduled()` (57) ومراقب دورة الحياة
  إن صار بلا فائدة.
- `lib/main.dart`
  - أزِل الاستيرادات (14 `alarm_screen`، 15 `reminders_provider`، و`med_dose_logger`).
  - أزِل `RemindersProvider` من `MultiProvider` (وبناءه) والخطوة `reschedule`.
  - أزِل خطوة `MedDoseLogger.run()` (`med_log`).
  - أزِل ربط `onAlarm` بـ `AlarmScreen`. **أبقِ** `onOpenNote` (فتح ملاحظة من إشعار).
- `lib/features/backup/backup_screen.dart` — أزِل استيراد `reminders_provider.dart`
  (14) وكل استدعاءات `refresh()/ensureScheduled()` بعد الاستعادة (≈312‑572).

### الخطوة د — الخدمات
- `lib/services/notification_service.dart` — أزِل جدولة تذكيرات الملاحظات/المنبّه
  (القنوات الحرجة، التكرار الهجريّ، إعادة الجدولة). **أبقِ**: التهيئة، الأذونات،
  `showPinnedNote`، الموجز الصباحيّ، وإشعارات النسخ/التحديث.
- `lib/services/med_dose_logger.dart`، `med_occurrences.dart` — احذفها.

### الخطوة هـ — حذف المجلدات والملفات
بعد أن يصبح `flutter analyze` نظيفًا من *الاستخدامات*، احذف:
- `lib/features/reminders/` (كامل المجلد)
- `lib/features/meds/`
- `lib/features/calendar/`
- `lib/features/sounds/`
- `lib/features/insights/`
- `lib/features/cleanup/`
- النماذج/المستودعات المرتبطة حصرًا: `data/models/reminder*.dart`،
  `med_dose.dart`، `data/repositories/reminder*.dart`، `med_repository.dart`
  (تحقّق ألّا يشير إليها شيء متبقٍّ قبل الحذف).

### الخطوة و — النصوص والثيم وقاعدة البيانات
- `lib/core/l10n/app_strings.dart` — احذف المفاتيح غير المستخدمة (تذكير/دواء/
  تقويم/نغمة) من `_ar` و`_en` معًا.
- `lib/core/theme/` — أزِل ألوان النغمات/المنبّه إن وُجدت.
- **قاعدة البيانات:** لا تحذف جداول `reminders`/`med_doses`/`reminder_log` من
  ترقيات قائمة (لئلّا تكسر قواعد المستخدمين الحاليّة). اكتفِ بإيقاف استخدامها؛ أو
  أضِف ترقية جديدة `DROP TABLE IF EXISTS` مع رفع `_dbVersion` إن أردت تنظيفًا.
- `pubspec.yaml` — بعد التأكّد بالمُصرِّف، أزِل الحزم التي لم تعد تُستورد:
  `table_calendar`، `hijri`، وربما `flutter_local_notifications`/`timezone`/
  `flutter_timezone` (فقط لو حُذفت كل الإشعارات — غالبًا تبقى للنسخ/التحديث).
  وأصول الصوت `assets/sounds/`.

---

## 3) اختبارات للتحديث/الحذف
- `test/reminder_helpers_test.dart`، `reminder_model_test.dart`،
  `hijri_recurrence_test.dart`، `med_dose_logger_test.dart` — تُحذف مع ميزاتها.
- أضِف اختبارًا يؤكّد أن الإقلاع وقائمة الملاحظات يعملان بلا المزوّدات المحذوفة.

---

## 4) قائمة تحقّق نهائيّة
- [ ] `flutter analyze` بلا أخطاء ولا تحذيرات استيراد ميّت.
- [ ] `flutter test` ينجح كاملًا.
- [ ] الإقلاع يعمل (لا `RemindersProvider`/`MedDoseLogger` مفقود في `main.dart`).
- [ ] فتح ملاحظة من إشعار ما زال يعمل (`onOpenNote`).
- [ ] تذكير «صدّر نسخة احتياطية» ما زال يظهر (لم يُحذف بالخطأ).
- [ ] الاستعادة من نسخة لا تستدعي مزوّد تذكيرات محذوفًا.
- [ ] رفع `version:` في `pubspec.yaml`.

---

## 5) ملفات مرجعيّة سريعة (خريطة الترابط المرصودة)
```
main.dart                → RemindersProvider, AlarmScreen, MedDoseLogger, reschedule
home/root_screen.dart    → RemindersProvider.refresh/ensureScheduled
home/home_screen.dart    → calendar, insights, reminders (مع إبقاء تذكير النسخ)
home/notes_provider.dart → noteHasReminder / noteIdsWithReminders
editor/note_editor*.dart → showReminderDialog (زرّ التذكير)
widgets/note_actions.dart→ reminder_dialog (بند «تذكير»)
widgets/note_card.dart   → شارة Icons.alarm (noteHasReminder)
settings/settings*.dart  → RemindersScreen, alarmTone, sound_options
backup/backup_screen.dart→ RemindersProvider بعد الاستعادة
services/notification_service.dart → جدولة التذكيرات/المنبّه (تُقلَّص لا تُحذف)
services/med_dose_logger.dart, med_occurrences.dart → تُحذف
```
