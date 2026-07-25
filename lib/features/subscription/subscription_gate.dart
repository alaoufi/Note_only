import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'subscribe_screen.dart';
import 'subscription_service.dart';

/// بوابة الاشتراك (نسخة Google Play). تُظهر المحتوى للمشتركين (وضمن التجربة)،
/// وإلا شاشة الاشتراك — مع الاحتفاظ الكامل بالبيانات.
class SubscriptionGate extends StatefulWidget {
  final Widget child;
  const SubscriptionGate({super.key, required this.child});

  @override
  State<SubscriptionGate> createState() => _SubscriptionGateState();
}

class _SubscriptionGateState extends State<SubscriptionGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SubscriptionService.instance.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // أعد فحص الاشتراك عند العودة (يلتقط شراءً تمّ من Google Play فورًا).
    if (state == AppLifecycleState.resumed) {
      SubscriptionService.instance.restore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionService>();
    switch (sub.state) {
      case SubState.loading:
        return const Scaffold(
            body: Center(child: CircularProgressIndicator()));
      case SubState.entitled:
        return widget.child;
      case SubState.expired:
      case SubState.storeUnavailable:
        return const SubscribeScreen();
    }
  }
}
