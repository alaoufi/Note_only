import 'package:flutter/material.dart';

import '../../services/crash_log_service.dart';

/// شاشة عرض سجلّ الأعطال المحليّ مع مشاركته أو مسحه.
class CrashLogScreen extends StatefulWidget {
  const CrashLogScreen({super.key});

  @override
  State<CrashLogScreen> createState() => _CrashLogScreenState();
}

class _CrashLogScreenState extends State<CrashLogScreen> {
  String _log = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await CrashLogService.instance.read();
    if (mounted) setState(() {
      _log = t.trim();
      _loading = false;
    });
  }

  Future<void> _clear() async {
    await CrashLogService.instance.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final empty = _log.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجلّ الأعطال'),
        actions: [
          if (!empty) ...[
            IconButton(
              tooltip: 'مشاركة',
              icon: const Icon(Icons.ios_share),
              onPressed: () => CrashLogService.instance.share(),
            ),
            IconButton(
              tooltip: 'مسح',
              icon: Icon(Icons.delete_outline, color: scheme.error),
              onPressed: _clear,
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : empty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 48, color: scheme.primary),
                      const SizedBox(height: 12),
                      const Text('لا توجد أعطال مسجّلة 🎉'),
                      const SizedBox(height: 6),
                      Text('يُسجَّل هنا أي خطأ تشغيل تلقائيًّا لتشاركه مع المطوّر.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Text('آخِر الأخطاء المسجّلة (الأحدث في الأسفل):',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    SelectableText(
                      _log,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 11, height: 1.5),
                    ),
                  ],
                ),
    );
  }
}
