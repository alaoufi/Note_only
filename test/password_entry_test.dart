import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mudhakkarati/data/models/password_entry.dart';

void main() {
  group('PasswordEntry', () {
    test('round-trip للحقول النصّية والعلاقات (بدون كلمة مرور)', () {
      const e = PasswordEntry(
        title: 'متجر أمازون',
        username: 'ali',
        email: 'ali@mail.com',
        website: 'amazon.com',
        relations: [3, 7],
        notes: 'حساب رئيسي',
      );
      final back = PasswordEntry.fromStoredJson(e.toStoredJson());
      expect(back.title, 'متجر أمازون');
      expect(back.username, 'ali');
      expect(back.email, 'ali@mail.com');
      expect(back.website, 'amazon.com');
      expect(back.relations, [3, 7]);
      expect(back.notes, 'حساب رئيسي');
    });

    test('ترحيل الصيغة القديمة: site→website و app→title', () {
      final oldJson = jsonEncode({
        'site': 'gmail.com',
        'app': 'Gmail',
        'username': 'u',
        'password_enc': '',
        'notes': 'n',
      });
      final e = PasswordEntry.fromStoredJson(oldJson);
      expect(e.website, 'gmail.com');
      expect(e.title, 'Gmail');
      expect(e.username, 'u');
      expect(e.relations, isEmpty);
    });

    test('titleFromJson يقرأ العنوان دون فكّ تشفير', () {
      final j = jsonEncode({'title': 'بنك', 'password_enc': 'xxx'});
      expect(PasswordEntry.titleFromJson(j), 'بنك');
      expect(PasswordEntry.titleFromJson('{}'), 'كلمة مرور');
      expect(PasswordEntry.titleFromJson(''), 'كلمة مرور');
    });

    test('isEmpty و displayTitle', () {
      expect(const PasswordEntry().isEmpty, isTrue);
      expect(const PasswordEntry(relations: [1]).isEmpty, isFalse);
      expect(const PasswordEntry(username: 'x').displayTitle, 'x');
      expect(const PasswordEntry(title: 'T', username: 'x').displayTitle, 'T');
    });
  });
}
