import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// فترة «كسر جلوس»: وقت البداية (دقائق من منتصف الليل) ومدّة الحركة بالدقائق.
/// نهاية الفترة = البداية + مدّة الحركة (تُحسب تلقائيًّا).
class BreakPeriod {
  int startMinutes; // من منتصف الليل (0..1439)
  int moveMinutes; // مدّة الحركة/القفل بالدقائق
  bool enabled;

  BreakPeriod({
    required this.startMinutes,
    required this.moveMinutes,
    this.enabled = true,
  });

  int get endMinutes => (startMinutes + moveMinutes).clamp(0, 24 * 60);

  Map<String, dynamic> toJson() =>
      {'s': startMinutes, 'm': moveMinutes, 'e': enabled};

  factory BreakPeriod.fromJson(Map<String, dynamic> j) => BreakPeriod(
        startMinutes: (j['s'] as num?)?.toInt() ?? 0,
        moveMinutes: (j['m'] as num?)?.toInt() ?? 5,
        enabled: j['e'] as bool? ?? true,
      );
}

/// خدمة تنبيه «لا تجلس طويلًا» — تقفل الشاشة بصمت خلال فترات الحركة المجدولة،
/// ولا تُفتح إلا بانتهاء المدّة أو إدخال الرمز المعقّد. كلّ الإعداد محليّ.
class MovementBreakService extends ChangeNotifier {
  MovementBreakService._();
  static final MovementBreakService instance = MovementBreakService._();

  static const _kEnabled = 'mb_enabled';
  static const _kPeriods = 'mb_periods';
  static const _kCode = 'mb_bypass_code';
  static const _kDone = 'mb_done_keys';

  bool _enabled = false;
  List<BreakPeriod> _periods = [];
  String _bypassCode = '';
  Set<String> _doneKeys = {};
  bool _loaded = false;

  bool get enabled => _enabled;
  List<BreakPeriod> get periods => List.unmodifiable(_periods);
  String get bypassCode => _bypassCode;
  bool get hasBypassCode => _bypassCode.trim().isNotEmpty;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final sp = await SharedPreferences.getInstance();
      _enabled = sp.getBool(_kEnabled) ?? false;
      _bypassCode = sp.getString(_kCode) ?? '';
      final raw = sp.getString(_kPeriods);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        _periods = list
            .map((e) => BreakPeriod.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      } else {
        _periods = _defaults();
      }
      // نُبقي مفاتيح «تمّ» ليومنا الحاليّ فقط.
      final today = _dayKey();
      _doneKeys = (sp.getStringList(_kDone) ?? const [])
          .where((k) => k.startsWith('$today-'))
          .toSet();
    } catch (_) {
      _periods = _defaults();
    }
    _loaded = true;
    notifyListeners();
  }

  List<BreakPeriod> _defaults() => [
        BreakPeriod(startMinutes: 11 * 60, moveMinutes: 5), // 11:00 لِـ 5 دقائق
        BreakPeriod(startMinutes: 16 * 60, moveMinutes: 5), // 16:00 لِـ 5 دقائق
      ];

  Future<void> save({
    bool? enabled,
    List<BreakPeriod>? periods,
    String? bypassCode,
  }) async {
    if (enabled != null) _enabled = enabled;
    if (periods != null) _periods = periods.take(3).toList();
    if (bypassCode != null) _bypassCode = bypassCode.trim();
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kEnabled, _enabled);
    await sp.setString(
        _kPeriods, jsonEncode(_periods.map((p) => p.toJson()).toList()));
    await sp.setString(_kCode, _bypassCode);
    notifyListeners();
  }

  // ---- منطق التفعيل ----

  String _dayKey([DateTime? d]) {
    final n = d ?? DateTime.now();
    return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
  }

  DateTime _todayAt(int minutes) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day).add(Duration(minutes: minutes));
  }

  bool _isDone(int index) => _doneKeys.contains('${_dayKey()}-$index');

  /// يُعلّم فترة اليوم بأنها انتهت (بالمدّة أو بالتخطّي) فلا تظهر ثانيةً اليوم.
  Future<void> markDone(int index) async {
    _doneKeys.add('${_dayKey()}-$index');
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setStringList(_kDone, _doneKeys.toList());
    } catch (_) {}
  }

  /// الفترة الفعّالة الآن (إن وُجدت) مع وقت انتهائها — أو null.
  ({int index, DateTime end})? activeBreakNow() {
    if (!_enabled) return null;
    final now = DateTime.now();
    for (var i = 0; i < _periods.length; i++) {
      final p = _periods[i];
      if (!p.enabled || p.moveMinutes <= 0) continue;
      final start = _todayAt(p.startMinutes);
      final end = start.add(Duration(minutes: p.moveMinutes));
      if (now.isAfter(start) && now.isBefore(end) && !_isDone(i)) {
        return (index: i, end: end);
      }
    }
    return null;
  }

  /// يتحقّق من رمز التخطّي (يقبل المسافات/التوحيد البسيط).
  bool checkCode(String input) {
    final a = input.trim();
    return hasBypassCode && a == _bypassCode.trim();
  }
}
