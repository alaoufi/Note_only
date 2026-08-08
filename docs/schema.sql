-- ============================================================================
-- مخطّط قاعدة بيانات «مذكراتي / ملاحظات»  —  إصدار المخطّط 21  (_dbVersion = 21)
-- ============================================================================
-- • قاعدة التطبيق الفعليّة مشفّرة بالكامل عبر SQLCipher (AES-256) بمفتاح محفوظ في
--   التخزين الآمن (Android Keystore) — انظر lib/data/database/db_key.dart.
-- • هذا الملف هو المخطّط المرجعيّ (البنية فقط، بلا تشفير وبلا بيانات) ويطابق ما
--   يُنشئه `_onCreate` في lib/data/database/app_database.dart بعد كل الترحيلات.
-- • لإنشاء نسخة مرجعيّة غير مشفّرة:  sqlite3 schema-reference.db < schema.sql
-- ============================================================================
PRAGMA foreign_keys = ON;

-- ---- التصنيفات -------------------------------------------------------------
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  color INTEGER NOT NULL,                     -- لون ARGB
  icon_code INTEGER NOT NULL,                 -- فهرس الأيقونة في kCategoryIcons (ليس codePoint)
  position INTEGER NOT NULL DEFAULT 0          -- ترتيب العرض
);

-- ---- الملاحظات -------------------------------------------------------------
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT,                                  -- معرّف عالميّ ثابت (للمزامنة السحابية)
  title TEXT NOT NULL DEFAULT '',
  content TEXT NOT NULL DEFAULT '',           -- Delta JSON (flutter_quill) للنصّ الغنيّ،
                                              -- أو JSON منظَّم لملاحظات password/treatment
  type TEXT NOT NULL DEFAULT 'text',          -- text/checklist/image/audio/pdf/drawing/password/treatment
  color INTEGER,                              -- لون خلفية (nullable)
  is_pinned INTEGER NOT NULL DEFAULT 0,
  is_favorite INTEGER NOT NULL DEFAULT 0,
  is_archived INTEGER NOT NULL DEFAULT 0,
  is_locked INTEGER NOT NULL DEFAULT 0,       -- ملاحظة مقفلة (تتطلّب مصادقة)
  is_deleted INTEGER NOT NULL DEFAULT 0,      -- في سلة المحذوفات
  deleted_at INTEGER,                         -- وقت الحذف (epoch ms)
  category_id INTEGER,
  image_path TEXT,
  audio_path TEXT,
  pdf_path TEXT,
  drawing_path TEXT,
  attachments TEXT,                           -- (v21) مرفقات متعددة كـ JSON (صور/PDF)
  bg_style INTEGER NOT NULL DEFAULT 0,        -- نمط خلفية الورق
  gradient TEXT,                              -- "dir:c1,c2[,c3]"
  rule_on_line INTEGER,                       -- تسطير لكل ملاحظة (null = الافتراضي العام)
  rule_thickness REAL,
  rule_opacity REAL,
  rule_line_height REAL,
  reminder_at INTEGER,                        -- (v19) تذكير بسيط للملاحظة (epoch ms، null = بلا)
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
);

-- ---- عناصر قوائم المهام ----------------------------------------------------
CREATE TABLE checklist_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  note_id INTEGER NOT NULL,
  text TEXT NOT NULL DEFAULT '',
  is_done INTEGER NOT NULL DEFAULT 0,
  position INTEGER NOT NULL DEFAULT 0,
  is_task INTEGER NOT NULL DEFAULT 1,          -- 1 = مهمة بمربع، 0 = سطر نصّ عادي
  FOREIGN KEY (note_id) REFERENCES notes (id) ON DELETE CASCADE
);

-- ---- الوسوم ----------------------------------------------------------------
CREATE TABLE tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  color INTEGER NOT NULL DEFAULT 0             -- 0 = اشتقاق تلقائيّ من الاسم
);

CREATE TABLE note_tags (
  note_id INTEGER NOT NULL,
  tag_id INTEGER NOT NULL,
  PRIMARY KEY (note_id, tag_id),
  FOREIGN KEY (note_id) REFERENCES notes (id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
);

-- ---- التذكيرات / المنبّهات --------------------------------------------------
CREATE TABLE reminders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  note_id INTEGER,                            -- اختياريّ (تنبيه مستقلّ ممكن)
  title TEXT,
  time INTEGER NOT NULL,                       -- موعد التنبيه (epoch ms)
  repeat TEXT NOT NULL DEFAULT 'once',         -- once/daily/weekly/monthly/yearly/hijriYearly
  is_active INTEGER NOT NULL DEFAULT 1,
  notification_id INTEGER NOT NULL,            -- معرّف إشعار النظام
  importance TEXT NOT NULL DEFAULT 'high',     -- low/medium/high/critical
  pre_alerts TEXT NOT NULL DEFAULT '',         -- تنبيهات مسبقة (دقائق مفصولة بفواصل)
  location TEXT NOT NULL DEFAULT '',           -- رابط خرائط للموعد
  attachment TEXT NOT NULL DEFAULT '',         -- مرفق الدعوة (صورة/PDF)
  interval_days INTEGER NOT NULL DEFAULT 0,    -- كورس دواء: الفاصل = أيام الراحة + 1
  dose_count INTEGER NOT NULL DEFAULT 0,       -- عدد جرعات الكورس
  FOREIGN KEY (note_id) REFERENCES notes (id) ON DELETE CASCADE
);

-- ---- قاعدة المعلومات العامة (بحث/تصفّح داخليّ) ------------------------------
CREATE TABLE info_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  main_specialty TEXT NOT NULL DEFAULT '',
  sub_specialty TEXT NOT NULL DEFAULT '',
  topic TEXT NOT NULL DEFAULT '',
  brief TEXT NOT NULL DEFAULT '',
  detail TEXT NOT NULL DEFAULT '',
  notes TEXT NOT NULL DEFAULT '',
  source TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL
);

-- ---- سجلّ جرعات الدواء (وضع العلاج) ----------------------------------------
CREATE TABLE med_doses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  dose TEXT,
  status TEXT NOT NULL DEFAULT 'taken',         -- taken/missed
  at INTEGER NOT NULL
);

-- ---- سجلّ التنبيهات المنفّذة ------------------------------------------------
CREATE TABLE reminder_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  reminder_id INTEGER,
  title TEXT NOT NULL,
  at INTEGER NOT NULL
);

-- ---- الفهارس ---------------------------------------------------------------
CREATE INDEX idx_notes_uuid ON notes (uuid);
CREATE INDEX idx_notes_category ON notes (category_id);
CREATE INDEX idx_notes_flags ON notes (is_deleted, is_archived);
CREATE INDEX idx_checklist_note ON checklist_items (note_id);
CREATE INDEX idx_reminders_note ON reminders (note_id);
CREATE INDEX idx_info_specialty ON info_entries (main_specialty, sub_specialty);

-- ---- بذور التصنيفات الافتراضية ---------------------------------------------
-- (icon_code = فهرس الأيقونة في kCategoryIcons، وليس codePoint)
INSERT INTO categories (name, color, icon_code, position) VALUES
  ('شخصي',   0xFF2E7D6B, 0, 0),
  ('عمل',    0xFF7E57C2, 1, 1),
  ('مهم',    0xFFEF5350, 2, 2),
  ('مواعيد', 0xFF26A69A, 3, 3),
  ('أفكار',  0xFFFFA726, 4, 4);
