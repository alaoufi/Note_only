import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// طلب تقييم داخل التطبيق بلباقة: بعد عدد من مرّات الفتح، مرّة واحدة فقط.
/// يستخدم واجهة Google الرسمية (لا يفتح المتجر، لا يزعج المستخدم).
class ReviewService {
  ReviewService._();

  static const _kOpens = 'review_opens';
  static const _kAsked = 'review_asked';
  static const _threshold = 4; // بعد رابع فتح

  /// يُستدعى عند بدء التطبيق. يطلب التقييم مرّة واحدة عند بلوغ العتبة.
  static Future<void> maybeAsk() async {
    try {
      final sp = await SharedPreferences.getInstance();
      if (sp.getBool(_kAsked) ?? false) return; // سبق الطلب
      final opens = (sp.getInt(_kOpens) ?? 0) + 1;
      await sp.setInt(_kOpens, opens);
      if (opens < _threshold) return;

      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
        await sp.setBool(_kAsked, true);
      }
    } catch (_) {/* لا نُفشل بدء التطبيق لأجل التقييم */}
  }
}
