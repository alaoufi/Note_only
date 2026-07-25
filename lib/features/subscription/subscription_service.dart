import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خطط الاشتراك في Google Play. عرّف هذه المنتجات في Play Console بنفس المعرّفات.
class SubPlans {
  static const monthly = 'sub_monthly'; // شهري
  static const semiannual = 'sub_semiannual'; // نصف سنوي
  static const annual = 'sub_annual'; // سنوي

  static const all = <String>{monthly, semiannual, annual};
}

/// حالة الاشتراك للعرض والتحكّم بالبوابة.
enum SubState {
  loading, // جارٍ الفحص (لا نُظهر القفل بعد)
  entitled, // مشترك فعّال (أو ضمن التجربة المجانية)
  expired, // لا اشتراك فعّال ⇒ يُطلب الاشتراك (البيانات محفوظة)
  storeUnavailable, // متجر Play غير متاح على الجهاز
}

/// خدمة اشتراكات Google Play (نسخة المتجر).
///
/// - التجربة المجانية (١٠ أيام) تُضبط كـ«عرض تجريبي» على الخطة في Play Console،
///   ويعامل النظامُ المستخدمَ في أثنائها كمشترك فعّال تلقائيًّا.
/// - عند الشراء يمنح Google الحقّ فورًا؛ نلتقطه من `purchaseStream` ونفكّ القفل
///   **آليًّا** دون أي إدخال يدوي.
/// - نُخزّن آخر حالة معروفة محليًّا مع مهلة سماح، كي يعمل التطبيق دون إنترنت مؤقّتًا.
/// - انتهاء الاشتراك ⇒ الحالة `expired` ⇒ تظهر شاشة الاشتراك مع **الاحتفاظ الكامل
///   بالبيانات** (لا نمسّ قاعدة الملاحظات إطلاقًا).
class SubscriptionService extends ChangeNotifier {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  SubState _state = SubState.loading;
  SubState get state => _state;

  final List<ProductDetails> _products = [];
  List<ProductDetails> get products => List.unmodifiable(_products);
  ProductDetails? productById(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool _busy = false;
  bool get busy => _busy;

  // تخزين آخر حالة معروفة + مهلة سماح دون إنترنت.
  static const _kEntitledUntil = 'sub_entitled_seen';
  static const _graceMs = 3 * 24 * 60 * 60 * 1000; // ٣ أيام سماح

  Future<void> init() async {
    final available = await _iap.isAvailable();
    if (!available) {
      // متجر غير متاح: اسمح بمهلة السماح إن سبق التفعيل، وإلا اطلب المتجر.
      _state = await _withinGrace() ? SubState.entitled : SubState.storeUnavailable;
      notifyListeners();
      return;
    }

    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (_) {},
    );

    await _loadProducts();
    // استعادة المشتريات ⇒ إن وُجد اشتراك فعّال يُعيد Google تسليمه فنُفعّل آليًّا.
    await _iap.restorePurchases();

    // مهلة قصيرة لوصول أحداث الاستعادة قبل الحكم بالانتهاء.
    Future.delayed(const Duration(seconds: 3), () {
      if (_state == SubState.loading) {
        _state = SubState.expired;
        notifyListeners();
      }
    });
  }

  Future<void> _loadProducts() async {
    try {
      final resp = await _iap.queryProductDetails(SubPlans.all);
      _products
        ..clear()
        ..addAll(resp.productDetails);
      _products.sort((a, b) => _order(a.id).compareTo(_order(b.id)));
    } catch (_) {/* نتجاهل — قد لا تكون المنتجات مُهيّأة بعد */}
    notifyListeners();
  }

  int _order(String id) => switch (id) {
        SubPlans.monthly => 0,
        SubPlans.semiannual => 1,
        SubPlans.annual => 2,
        _ => 9,
      };

  /// شراء اشتراك (يفتح واجهة الدفع في Google Play). التفعيل آليّ بعد الدفع.
  Future<void> buy(ProductDetails product) async {
    _busy = true;
    notifyListeners();
    try {
      final param = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: param);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// استعادة اشتراك سابق (تغيير جهاز/إعادة تثبيت).
  Future<void> restore() async {
    _busy = true;
    notifyListeners();
    try {
      await _iap.restorePurchases();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    var entitled = false;
    for (final p in purchases) {
      if (p.status == PurchaseStatus.pending) continue;
      if (p.status == PurchaseStatus.error || p.status == PurchaseStatus.canceled) {
        continue;
      }
      final isOurs = SubPlans.all.contains(p.productID);
      if (isOurs &&
          (p.status == PurchaseStatus.purchased ||
              p.status == PurchaseStatus.restored)) {
        entitled = true;
      }
      // يجب إكمال أي عملية معلّقة الإتمام وإلا يستردّها Google.
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }

    if (entitled) {
      await _markSeen();
      _state = SubState.entitled;
      notifyListeners();
    } else if (_state == SubState.loading) {
      // لم يصل أي حقّ فعّال بعد؛ نترك مهلة init لتحسم.
    }
  }

  Future<void> _markSeen() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(_kEntitledUntil, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<bool> _withinGrace() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final last = sp.getInt(_kEntitledUntil);
      if (last == null) return false;
      return DateTime.now().millisecondsSinceEpoch - last < _graceMs;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
