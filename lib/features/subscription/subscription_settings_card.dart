import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'subscribe_screen.dart';
import 'subscription_service.dart';

/// بطاقة الاشتراك في الإعدادات (نسخة المتجر): الحالة + إدارة + استعادة.
/// إظهار «إدارة الاشتراك» إلزاميّ لسياسة Google Play.
class SubscriptionSettingsCard extends StatelessWidget {
  const SubscriptionSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionService>();
    final scheme = Theme.of(context).colorScheme;
    final expired = sub.state == SubState.expired ||
        sub.state == SubState.storeUnavailable;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.workspace_premium, color: scheme.primary),
            title: const Text('الاشتراك',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(sub.statusLabel()),
          ),
          if (expired)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SubscribeScreen()),
                  ),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('اشترك الآن'),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: sub.busy ? null : () => sub.openManage(),
                      icon: const Icon(Icons.manage_accounts, size: 18),
                      label: const Text('إدارة الاشتراك'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: sub.busy ? null : () => sub.restore(),
                    icon: const Icon(Icons.restore, size: 18),
                    label: const Text('استعادة'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
