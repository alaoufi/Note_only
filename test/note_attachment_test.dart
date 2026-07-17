import 'package:flutter_test/flutter_test.dart';
import 'package:mudhakkarati/data/models/note_attachment.dart';

void main() {
  group('NoteAttachment', () {
    test('encode/decode round-trip لعدّة مرفقات', () {
      const list = [
        NoteAttachment(path: '/a/1.jpg', kind: 'image'),
        NoteAttachment(path: '/a/2.pdf', kind: 'pdf', name: 'عقد.pdf'),
      ];
      final raw = NoteAttachment.encode(list);
      final back = NoteAttachment.decode(raw);
      expect(back.length, 2);
      expect(back[0].isImage, isTrue);
      expect(back[1].isPdf, isTrue);
      expect(back[1].name, 'عقد.pdf');
    });

    test('قائمة فارغة ترمّز إلى null', () {
      expect(NoteAttachment.encode(const []), isNull);
    });

    test('نص تالف/فارغ يفكّ إلى قائمة فارغة', () {
      expect(NoteAttachment.decode(null), isEmpty);
      expect(NoteAttachment.decode(''), isEmpty);
      expect(NoteAttachment.decode('{ليس JSON'), isEmpty);
    });

    test('يتجاهل المدخلات بلا مسار', () {
      final back = NoteAttachment.decode('[{"k":"image"},{"p":"/x.jpg","k":"image"}]');
      expect(back.length, 1);
      expect(back.first.path, '/x.jpg');
    });
  });
}
