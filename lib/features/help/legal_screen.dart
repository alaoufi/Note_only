import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import 'user_guide_content.dart';

/// شاشة «الخصوصية وإخلاء المسؤولية» — بارزة ومباشرة من القائمة الجانبية،
/// بمحتوى مفصّل مترجَم لكل اللغات (يتبع لغة المستخدم).
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  static const _ids = ['privacy', 'disclaimer'];

  String _title(String lang) => switch (lang) {
        'ar' => 'الخصوصية وإخلاء المسؤولية',
        'tr' => 'Gizlilik ve sorumluluk reddi',
        'es' => 'Privacidad y responsabilidad',
        'fa' => 'حریم خصوصی و سلب مسئولیت',
        'id' => 'Privasi & penafian',
        'fr' => 'Confidentialité et responsabilité',
        'de' => 'Datenschutz & Haftung',
        _ => 'Privacy & Disclaimer',
      };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lang = s.locale.languageCode;
    final scheme = Theme.of(context).colorScheme;
    final topics =
        guideTopics.where((t) => _ids.contains(t.id)).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title(lang),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
        children: [
          for (final t in topics)
            Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                          child: Icon(t.icon,
                              color: scheme.onPrimaryContainer, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(t.localizedTitle(lang),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 17)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      t.localizedBody(lang),
                      style: TextStyle(
                          fontSize: 14.5,
                          height: 1.7,
                          color: scheme.onSurface.withOpacity(0.9)),
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
