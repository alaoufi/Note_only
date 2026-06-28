import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import 'user_guide_content.dart';

/// دليل الاستخدام التفاعليّ: فهرس في الأعلى **ينقلك** للقسم عند الضغط، وكل قسم
/// يحوي شرحًا تفصيليًّا. المحتوى يتبع لغة المستخدم (مع رجوع للإنجليزية).
class UserGuideScreen extends StatefulWidget {
  const UserGuideScreen({super.key});

  @override
  State<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  final _scrollCtrl = ScrollController();
  // مفتاح لكل قسم كي يستطيع الفهرس التمرير إليه.
  final Map<String, GlobalKey> _keys = {
    for (final t in guideTopics) t.id: GlobalKey(),
  };

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _goTo(String id) async {
    final ctx = _keys[id]?.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
      alignment: 0.04, // اترك مسافة صغيرة أعلى القسم.
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lang = s.locale.languageCode;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('user_guide'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 32),
        children: [
          // ===== الفهرس (ينقلك للقسم) =====
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.menu_book_outlined,
                          size: 20, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        _indexLabel(lang),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: scheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in guideTopics)
                        ActionChip(
                          avatar: Icon(t.icon,
                              size: 18, color: scheme.onSecondaryContainer),
                          label: Text(t.localizedTitle(lang)),
                          backgroundColor: scheme.secondaryContainer,
                          labelStyle:
                              TextStyle(color: scheme.onSecondaryContainer),
                          onPressed: () => _goTo(t.id),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ===== الأقسام التفصيلية =====
          for (final t in guideTopics)
            Padding(
              key: _keys[t.id],
              padding: const EdgeInsets.only(bottom: 12),
              child: _TopicCard(
                icon: t.icon,
                title: t.localizedTitle(lang),
                body: t.localizedBody(lang),
                onBackToIndex: () => _scrollCtrl.animateTo(0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut),
                backLabel: _backLabel(lang),
              ),
            ),
        ],
      ),
    );
  }

  String _indexLabel(String lang) => switch (lang) {
        'ar' => 'الفهرس — اضغط للانتقال',
        'tr' => 'İçindekiler — gitmek için dokunun',
        'es' => 'Índice — toca para ir',
        _ => 'Index — tap to jump',
      };

  String _backLabel(String lang) => switch (lang) {
        'ar' => 'أعلى الفهرس',
        'tr' => 'İçindekilere dön',
        'es' => 'Volver al índice',
        _ => 'Back to index',
      };
}

class _TopicCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onBackToIndex;
  final String backLabel;
  const _TopicCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onBackToIndex,
    required this.backLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(icon, color: scheme.onPrimaryContainer, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              body,
              style: TextStyle(
                  fontSize: 14.5,
                  height: 1.7,
                  color: scheme.onSurface.withOpacity(0.9)),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: onBackToIndex,
                icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                label: Text(backLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
