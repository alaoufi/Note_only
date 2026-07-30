import 'package:flutter_test/flutter_test.dart';
import 'package:mudhakkarati/services/ai_service.dart';

void main() {
  group('AiActionMeta', () {
    test('كل إجراء له تسمية ووصف عربيّان غير فارغين', () {
      for (final a in AiAction.values) {
        expect(a.label.trim(), isNotEmpty, reason: '$a label');
        expect(a.hint.trim(), isNotEmpty, reason: '$a hint');
      }
    });

    test('التسميات مميّزة (لا تكرار)', () {
      final labels = AiAction.values.map((a) => a.label).toSet();
      expect(labels.length, AiAction.values.length);
    });

    test('النموذج الافتراضي هو الأحدث', () {
      expect(AiService.defaultModel, 'claude-opus-5');
    });
  });
}
