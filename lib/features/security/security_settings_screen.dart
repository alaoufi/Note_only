import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../services/license_service.dart';
import '../../services/security_service.dart';
import '../../widgets/ui_kit.dart';
import 'pin_entry.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final _sec = SecurityService.instance;
  bool _lockEnabled = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _lockEnabled = await _sec.isLockEnabled();
    _biometricEnabled = await _sec.isBiometricEnabled();
    _biometricAvailable = await _sec.canUseBiometrics();
    setState(() => _loaded = true);
  }

  Future<bool> _setupPin() async {
    final s = S.of(context);
    String? first;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: PinEntry(
              title: first == null ? s.t('set_pin') : s.t('confirm_pin'),
              onSubmit: (pin) async {
                if (first == null) {
                  setSheet(() => first = pin);
                  return false; // اطلب التأكيد دون إغلاق.
                }
                if (first == pin) {
                  await _sec.setPin(pin);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                  return true;
                }
                setSheet(() => first = null); // غير متطابق، أعد البداية.
                return false;
              },
            ),
          );
        },
      ),
    );
    if (ok == true) await _load();
    return ok == true;
  }

  /// إلغاء تفعيل هذا الجهاز (للمالك/الاختبار): يمسح الترخيص المخزَّن فتظهر شاشة
  /// التفعيل عند إعادة فتح التطبيق. يُعاد التفعيل بكود جديد من المولّد.
  Future<void> _deactivateLicense() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.lock_reset),
        title: const Text('إلغاء التفعيل؟'),
        content: const Text(
            'سيُمسح ترخيص هذا الجهاز، فتظهر شاشة التفعيل عند إعادة فتح التطبيق '
            '(للاختبار). يمكنك إعادة التفعيل بكود جديد في أي وقت.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إلغاء التفعيل')),
        ],
      ),
    );
    if (ok != true) return;
    await LicenseService.instance.deactivate();
    if (!mounted) return;
    setState(() {}); // حدّث بطاقة حالة الترخيص.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('تم إلغاء التفعيل — أعد تشغيل التطبيق لاختبار شاشة التفعيل')));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: gradientAppBar(context, s.t('security')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const GradientIcon(Icons.lock_outline),
                  title: Text(s.t('app_lock'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(s.t('use_pin')),
                  value: _lockEnabled,
                  onChanged: (v) async {
                    if (v) {
                      // تفعيل قفل التطبيق صراحةً: اضبط الرقم ثم فعّل القفل.
                      if (await _setupPin()) {
                        await _sec.enableLock();
                        await _load();
                      }
                    } else {
                      await _sec.disableLock();
                      await _load();
                    }
                  },
                ),
                if (_lockEnabled)
                  ListTile(
                    leading: const Icon(Icons.password),
                    title: Text(s.t('set_pin')),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: _setupPin,
                  ),
                if (_lockEnabled && _biometricAvailable)
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint),
                    title: Text(s.t('use_biometric')),
                    value: _biometricEnabled,
                    onChanged: (v) async {
                      await _sec.setBiometric(v);
                      await _load();
                    },
                  ),
              ],
            ),
          ),
          // بطاقة الترخيص (تظهر فقط عند ضبط مفتاح عامّ — أي خارج وضع التطوير).
          FutureBuilder<LicenseInfo>(
            future: LicenseService.instance.info(),
            builder: (context, snap) {
              final info = snap.data;
              if (info == null || info.state == LicenseState.disabled) {
                return const SizedBox.shrink();
              }
              final status = switch (info.state) {
                LicenseState.active => info.permanent
                    ? 'مفعّل — دائم'
                    : 'مفعّل — يتبقّى ${info.daysLeft} يوم',
                LicenseState.expired => 'انتهت صلاحية التفعيل',
                _ => 'غير مفعّل',
              };
              return AppCard(
                child: Column(
                  children: [
                    ListTile(
                      leading:
                          const GradientIcon(Icons.verified_user_outlined),
                      title: const Text('ترخيص التطبيق',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(status),
                    ),
                    ListTile(
                      leading: Icon(Icons.lock_reset, color: scheme.error),
                      title: Text('إلغاء التفعيل (للاختبار)',
                          style: TextStyle(color: scheme.error)),
                      subtitle: const Text(
                          'امسح ترخيص هذا الجهاز لاختبار شاشة التفعيل'),
                      onTap: _deactivateLicense,
                    ),
                  ],
                ),
              );
            },
          ),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: scheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'يمكنك قفل ملاحظة معينة من قائمة خيارات الملاحظة (اضغط مطولاً على الملاحظة). يتطلب فتحها الرقم السري أو البصمة.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
