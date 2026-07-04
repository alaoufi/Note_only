import 'dart:convert';

import '../../services/vault_service.dart';

/// بيانات ملاحظة كلمات المرور (حقول منظمة).
///
/// تُخزَّن داخل حقل `content` للملاحظة كـ JSON، مع تشفير كلمة المرور فقط
/// بمفتاح الخزنة (VaultService). باقي الحقول تبقى نصًّا ليعمل البحث.
///
/// الترتيب: العنوان، المستخدم، كلمة المرور، البريد، الموقع، العلاقات، ملاحظات.
/// «العلاقات» = معرّفات ملاحظات كلمات مرور أخرى مرتبطة (كبريد يسجَّل به متجر).
class PasswordEntry {
  final String title; // العنوان
  final String username; // المستخدم
  final String password; // كلمة المرور (نص صريح في الذاكرة فقط)
  final String email; // البريد الإلكتروني
  final String website; // الموقع الإلكتروني
  final List<int> relations; // العلاقات (معرّفات ملاحظات مرتبطة)
  final String notes; // ملاحظات

  const PasswordEntry({
    this.title = '',
    this.username = '',
    this.password = '',
    this.email = '',
    this.website = '',
    this.relations = const [],
    this.notes = '',
  });

  PasswordEntry copyWith({
    String? title,
    String? username,
    String? password,
    String? email,
    String? website,
    List<int>? relations,
    String? notes,
  }) {
    return PasswordEntry(
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      email: email ?? this.email,
      website: website ?? this.website,
      relations: relations ?? this.relations,
      notes: notes ?? this.notes,
    );
  }

  /// يحوّل إلى JSON قابل للتخزين مع تشفير كلمة المرور.
  /// يجب استدعاء VaultService.instance.ensureKey() مسبقًا.
  String toStoredJson() {
    return jsonEncode({
      'title': title,
      'username': username,
      'password_enc':
          password.isEmpty ? '' : VaultService.instance.encrypt(password),
      'email': email,
      'website': website,
      'relations': relations,
      'notes': notes,
    });
  }

  /// يقرأ من JSON المخزَّن ويفك تشفير كلمة المرور. يدعم الصيغة القديمة
  /// (site/app) بالترحيل: الموقع القديم ⇐ الموقع، والتطبيق القديم ⇐ العنوان.
  factory PasswordEntry.fromStoredJson(String raw) {
    if (raw.trim().isEmpty) return const PasswordEntry();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final enc = (map['password_enc'] as String?) ?? '';
      final oldSite = (map['site'] as String?) ?? '';
      final oldApp = (map['app'] as String?) ?? '';
      return PasswordEntry(
        title: (map['title'] as String?)?.isNotEmpty == true
            ? map['title'] as String
            : oldApp,
        username: (map['username'] as String?) ?? '',
        password: enc.isEmpty ? '' : VaultService.instance.decrypt(enc),
        email: (map['email'] as String?) ?? '',
        website: (map['website'] as String?)?.isNotEmpty == true
            ? map['website'] as String
            : oldSite,
        relations: (map['relations'] as List?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            const [],
        notes: (map['notes'] as String?) ?? '',
      );
    } catch (_) {
      return const PasswordEntry();
    }
  }

  /// يقرأ العنوان المعروض فقط دون فكّ تشفير (لقوائم الاختيار/العلاقات).
  static String titleFromJson(String raw) {
    if (raw.trim().isEmpty) return 'كلمة مرور';
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      for (final k in ['title', 'app', 'username', 'website', 'site', 'email']) {
        final v = (map[k] as String?)?.trim() ?? '';
        if (v.isNotEmpty) return v;
      }
    } catch (_) {}
    return 'كلمة مرور';
  }

  /// نصّ قابل للبحث (عنوان/مستخدم/بريد/موقع/ملاحظات) دون فكّ تشفير كلمة المرور.
  static String searchableFromJson(String raw) {
    if (raw.trim().isEmpty) return '';
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return [
        m['title'],
        m['app'],
        m['username'],
        m['email'],
        m['website'],
        m['site'],
        m['notes'],
      ].whereType<String>().join(' ');
    } catch (_) {
      return '';
    }
  }

  /// نص مختصر يُعرض في البطاقة (بدون كلمة المرور).
  String get displayTitle {
    if (title.trim().isNotEmpty) return title;
    if (username.trim().isNotEmpty) return username;
    if (website.trim().isNotEmpty) return website;
    if (email.trim().isNotEmpty) return email;
    return 'كلمة مرور';
  }

  bool get isEmpty =>
      title.trim().isEmpty &&
      username.trim().isEmpty &&
      password.trim().isEmpty &&
      email.trim().isEmpty &&
      website.trim().isEmpty &&
      relations.isEmpty &&
      notes.trim().isEmpty;
}
