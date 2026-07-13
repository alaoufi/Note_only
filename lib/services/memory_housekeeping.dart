import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

/// تنظيف الذاكرة والملفات المؤقتة بعمق — يُستدعى عند خروج التطبيق/تعطيله.
///
/// **مهم:** لا يمسّ هذا الصنف مجلد المرفقات (attachments) ولا قاعدة البيانات
/// ولا مفاتيح التشفير إطلاقًا. يقتصر على:
///   1) تفريغ ذاكرة الصور (imageCache) من الـ RAM.
///   2) حذف الملفات المؤقّتة/الكاش التي يخلّفها منتقي الصور والنظام.
class MemoryHousekeeping {
  MemoryHousekeeping._();
  static final MemoryHousekeeping instance = MemoryHousekeeping._();

  /// يفرّغ ذاكرة الصور من الـ RAM فورًا (يُستدعى عند التوقّف المؤقّت والخروج).
  void clearRuntimeCaches() {
    try {
      final cache = PaintingBinding.instance.imageCache;
      cache.clear();
      cache.clearLiveImages();
    } catch (_) {
      // لا نُفشل الخروج بسبب فشل التفريغ.
    }
  }

  /// يحذف محتويات المجلّدات المؤقّتة/الكاش بعمق (لا يمسّ المرفقات ولا القاعدة).
  ///
  /// منتقي الصور والكاميرا يتركان نسخًا مؤقّتة في مجلّد الكاش بعد أن نكون قد
  /// نسخنا الصورة إلى المرفقات — فتتراكم وتلتهم المساحة. هنا ننظّفها.
  Future<void> purgeTempFiles() async {
    for (final getter in <Future<Directory> Function()>[
      getTemporaryDirectory,
      _cacheDirOrNull,
    ]) {
      try {
        final dir = await getter();
        if (await dir.exists()) {
          await for (final entity in dir.list(followLinks: false)) {
            try {
              await entity.delete(recursive: true);
            } catch (_) {
              // ملف قيد الاستخدام أو محميّ — نتجاوزه بهدوء.
            }
          }
        }
      } catch (_) {
        // بعض المنصّات قد لا توفّر المجلد — نتجاوز.
      }
    }
  }

  Future<Directory> _cacheDirOrNull() async {
    // getApplicationCacheDirectory متوفّر على أندرويد؛ إن لم يتوفّر نرمي فيُتجاوَز.
    return getApplicationCacheDirectory();
  }

  /// تنظيف كامل (ذاكرة + ملفات مؤقّتة) — يُستدعى عند الخروج/التعطيل.
  Future<void> deepClean() async {
    clearRuntimeCaches();
    await purgeTempFiles();
  }
}
