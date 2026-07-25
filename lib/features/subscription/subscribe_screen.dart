import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import 'subscription_service.dart';

/// شاشة الاشتراك (نسخة المتجر). تظهر عند عدم وجود اشتراك فعّال — والبيانات محفوظة.
class SubscribeScreen extends StatelessWidget {
  const SubscribeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sub = context.watch<SubscriptionService>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium,
                      size: 64, color: scheme.primary),
                  const SizedBox(height: 14),
                  Text('اشترك لمواصلة الاستخدام',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'جرّب مجانًا ١٠ أيام، ثم اختر خطة تناسبك. '
                    'ملاحظاتك محفوظة بالكامل ولن تُفقد.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),

                  if (sub.state == SubState.storeUnavailable)
                    _notice(context,
                        'خدمة Google Play غير متاحة على هذا الجهاز. '
                        'تأكّد من تثبيت «خدمات Google Play» وتسجيل الدخول بحساب Google.')
                  else if (sub.products.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 10),
                        Text('جارٍ تحميل الخطط…',
                            style: TextStyle(color: scheme.onSurfaceVariant)),
                      ]),
                    )
                  else
                    ...sub.products.map((p) => _planCard(context, sub, p)),

                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: sub.busy ? null : () => sub.restore(),
                    icon: const Icon(Icons.restore, size: 18),
                    label: const Text('استعادة اشتراك سابق'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'يُدار الاشتراك ويُلغى من Google Play. يُجدَّد تلقائيًّا حتى الإلغاء.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _planCard(
      BuildContext context, SubscriptionService sub, ProductDetails p) {
    final scheme = Theme.of(context).colorScheme;
    final title = _title(p.id);
    final best = p.id == SubPlans.annual;
    return Card(
      elevation: best ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: best ? scheme.primary : scheme.outlineVariant,
            width: best ? 1.6 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    if (best) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('الأوفر',
                            style: TextStyle(
                                color: scheme.onPrimary, fontSize: 11)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(p.price,
                      style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ],
              ),
            ),
            FilledButton(
              onPressed: sub.busy ? null : () => sub.buy(p),
              child: const Text('اشترك'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notice(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: scheme.onErrorContainer)),
    );
  }

  String _title(String id) => switch (id) {
        SubPlans.monthly => 'شهري',
        SubPlans.semiannual => 'نصف سنوي (٦ أشهر)',
        SubPlans.annual => 'سنوي',
        _ => id,
      };
}
