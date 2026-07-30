import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// إجراءات مساعد الذكاء الاصطناعي على نصّ الملاحظة.
enum AiAction { summarize, expand, rewrite, proofread, continueWriting, custom }

extension AiActionMeta on AiAction {
  /// اسم الإجراء بالعربية (للعرض).
  String get label => switch (this) {
        AiAction.summarize => 'تلخيص',
        AiAction.expand => 'توسيع',
        AiAction.rewrite => 'إعادة صياغة',
        AiAction.proofread => 'تدقيق إملائي ولغوي',
        AiAction.continueWriting => 'متابعة الكتابة',
        AiAction.custom => 'تعليمات مخصّصة',
      };

  /// وصف موجز للإجراء.
  String get hint => switch (this) {
        AiAction.summarize => 'استخلاص أهمّ النقاط في فقرة موجزة',
        AiAction.expand => 'إثراء النصّ بتفاصيل وشرح إضافيّ',
        AiAction.rewrite => 'صياغة أوضح وأجمل مع الحفاظ على المعنى',
        AiAction.proofread => 'تصحيح الإملاء والنحو وعلامات الترقيم',
        AiAction.continueWriting => 'إكمال النصّ بأسلوبٍ متّسق',
        AiAction.custom => 'اطلب ما تريد من المساعد بشأن هذا النص',
      };

  /// تعليمات النظام لكل إجراء (تُوجّه النموذج).
  String get _system {
    const base =
        'أنت مساعد كتابة عربيّ محترف داخل تطبيق ملاحظات. أجب بالعربية الفصحى '
        'السليمة ما لم يكن النصّ الأصليّ بلهجة أو لغة أخرى فتُحافظ عليها. '
        'أعد **النصّ الناتج فقط** دون مقدّمات ولا شرح ولا علامات اقتباس ولا '
        'ترويسات. حافظ على أسطر القوائم والفقرات كما هي عند الحاجة.';
    return switch (this) {
      AiAction.summarize =>
        '$base مهمّتك: لخّص النصّ التالي في فقرة موجزة تُبرز أهمّ الأفكار.',
      AiAction.expand =>
        '$base مهمّتك: وسّع النصّ التالي بتفاصيل وأمثلة وشرحٍ يثري المعنى دون حشو.',
      AiAction.rewrite =>
        '$base مهمّتك: أعد صياغة النصّ التالي بأسلوبٍ أوضح وأسلس مع الحفاظ التامّ على المعنى.',
      AiAction.proofread =>
        '$base مهمّتك: صحّح الأخطاء الإملائية والنحوية وعلامات الترقيم في النصّ '
            'التالي دون تغيير المعنى ولا الأسلوب. أعد النصّ مصحَّحًا.',
      AiAction.continueWriting =>
        '$base مهمّتك: تابع كتابة النصّ التالي من حيث انتهى بأسلوبٍ ونبرةٍ متّسقين. '
            'أعد **الإضافة الجديدة فقط** دون تكرار ما سبق.',
      AiAction.custom => base,
    };
  }
}

/// استثناء ودّي برسالة عربية جاهزة للعرض.
class AiException implements Exception {
  final String message;
  AiException(this.message);
  @override
  String toString() => message;
}

/// مساعد الذكاء الاصطناعي للملاحظات — يتصل بـ Claude API.
///
/// طريقتان للإعداد (يكفي إحداهما):
/// 1. **وسيط (proxy)**: يضع المطوّر رابط خادم وسيط يحتفظ بمفتاح المزوّد سرًّا
///    (مثل Cloudflare Worker المرفق). هذا الخيار المناسب لتطبيقٍ منشور، إذ لا
///    يُخزَّن أيّ مفتاح على الجهاز.
/// 2. **مفتاح خاص (BYOK)**: يُدخل المستخدم مفتاح Anthropic الخاصّ به فيُخزَّن في
///    تخزين الجهاز الآمن ويُرسل مباشرةً إلى الـ API.
///
/// كلا المسارين يرسل **نفس جسم الطلب** (بنية رسائل Anthropic)؛ يختلف فقط الرابط
/// والترويسات: الوسيط يحقن المفتاح وترويسة الإصدار من جانبه.
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  static const _kEndpoint = 'ai_endpoint'; // رابط الوسيط
  static const _kProxySecret = 'ai_proxy_secret'; // سرّ مشترك اختياريّ للوسيط
  static const _kApiKey = 'ai_api_key'; // مفتاح المستخدم (BYOK)
  static const _kModel = 'ai_model';

  /// النموذج الافتراضي — الأحدث والأقدر. يمكن للمطوّر تغييره من الإعدادات.
  static const defaultModel = 'claude-opus-5';
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const _anthropicVersion = '2023-06-01';

  /// رابط الخدمة وسرّه المضمَّنان وقت البناء (للنسخة المنشورة) — كي يعمل المساعد
  /// لكل المستخدمين دون إعداد. تُبنى عبر:
  /// `flutter build appbundle --dart-define=AI_ENDPOINT=https://…`
  /// ويتجاوزهما أيّ إعداد يحفظه المستخدم على جهازه.
  static const _buildEndpoint = String.fromEnvironment('AI_ENDPOINT');
  static const _buildSecret = String.fromEnvironment('AI_PROXY_SECRET');

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// يتغيّر عند تعديل الإعداد كي تُحدّث الواجهات إظهار/إخفاء زرّ المساعد.
  final ValueNotifier<bool> ready = ValueNotifier<bool>(false);

  String? _endpoint;
  String? _apiKey;
  String? _proxySecret;
  String? _model;
  bool _loaded = false;

  /// يُحمّل الإعداد من التخزين الآمن (مرّة، ويُعاد عند [reload]).
  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _endpoint = (await _storage.read(key: _kEndpoint))?.trim();
    _apiKey = (await _storage.read(key: _kApiKey))?.trim();
    _proxySecret = (await _storage.read(key: _kProxySecret))?.trim();
    _model = (await _storage.read(key: _kModel))?.trim();
    _loaded = true;
    ready.value = isConfigured;
  }

  /// يعيد قراءة الإعداد (بعد الحفظ من شاشة الإعدادات).
  Future<void> reload() async {
    _loaded = false;
    await _ensureLoaded();
  }

  /// رابط الوسيط الفعّال: إعداد المستخدم إن وُجد، وإلا المضمَّن وقت البناء.
  String get _effEndpoint =>
      (_endpoint != null && _endpoint!.isNotEmpty) ? _endpoint! : _buildEndpoint;

  /// سرّ الوسيط الفعّال (بنفس المنطق).
  String get _effSecret =>
      (_proxySecret != null && _proxySecret!.isNotEmpty)
          ? _proxySecret!
          : _buildSecret;

  /// هل المساعد مُهيّأ (وسيط أو مفتاح خاص)؟
  bool get isConfigured =>
      _effEndpoint.isNotEmpty || (_apiKey != null && _apiKey!.isNotEmpty);

  /// يهيّئ الحالة عند بدء التطبيق (لضبط [ready]).
  Future<void> init() => _ensureLoaded();

  // ---- قراءة/حفظ الإعداد (لشاشة الإعدادات) ----

  Future<String> endpoint() async {
    await _ensureLoaded();
    return _endpoint ?? '';
  }

  Future<String> proxySecret() async {
    await _ensureLoaded();
    return _proxySecret ?? '';
  }

  Future<bool> hasApiKey() async {
    await _ensureLoaded();
    return _apiKey != null && _apiKey!.isNotEmpty;
  }

  Future<String> model() async {
    await _ensureLoaded();
    return (_model == null || _model!.isEmpty) ? defaultModel : _model!;
  }

  Future<void> saveConfig({
    String? endpoint,
    String? proxySecret,
    String? apiKey,
    String? model,
  }) async {
    Future<void> put(String k, String? v) async {
      final t = v?.trim() ?? '';
      if (t.isEmpty) {
        await _storage.delete(key: k);
      } else {
        await _storage.write(key: k, value: t);
      }
    }

    if (endpoint != null) await put(_kEndpoint, endpoint);
    if (proxySecret != null) await put(_kProxySecret, proxySecret);
    if (apiKey != null) await put(_kApiKey, apiKey);
    if (model != null) await put(_kModel, model);
    await reload();
  }

  /// يمسح كامل إعداد المساعد.
  Future<void> clear() async {
    await _storage.delete(key: _kEndpoint);
    await _storage.delete(key: _kProxySecret);
    await _storage.delete(key: _kApiKey);
    await _storage.delete(key: _kModel);
    await reload();
  }

  /// ينفّذ إجراءً على [text] ويعيد النصّ الناتج.
  ///
  /// [instruction] يُستخدم مع [AiAction.custom] (وصف ما يريده المستخدم).
  Future<String> run(
    AiAction action,
    String text, {
    String? instruction,
  }) async {
    await _ensureLoaded();
    if (!isConfigured) {
      throw AiException('لم يُفعّل المساعد بعد. أضِف رابط الخدمة أو مفتاحًا من الإعدادات.');
    }
    final clean = text.trim();
    if (clean.isEmpty) {
      throw AiException('لا يوجد نصّ لمعالجته.');
    }

    final system = action == AiAction.custom
        ? '${AiAction.custom._system} '
            'مهمّتك حسب طلب المستخدم: ${(instruction ?? '').trim()}'
        : action._system;

    final userContent = action == AiAction.custom
        ? 'النصّ:\n$clean'
        : clean;

    final body = <String, dynamic>{
      'model': await model(),
      'max_tokens': 4096,
      'system': system,
      'messages': [
        {'role': 'user', 'content': userContent},
      ],
    };

    final effEndpoint = _effEndpoint;
    final useProxy = effEndpoint.isNotEmpty;
    final uri = Uri.parse(useProxy ? effEndpoint : _apiUrl);
    final headers = <String, String>{'content-type': 'application/json'};
    if (useProxy) {
      // الوسيط يحقن مفتاح المزوّد وترويسة الإصدار؛ نمرّر سرًّا مشتركًا اختياريًّا.
      final secret = _effSecret;
      if (secret.isNotEmpty) headers['x-app-secret'] = secret;
    } else {
      headers['x-api-key'] = _apiKey!;
      headers['anthropic-version'] = _anthropicVersion;
    }

    http.Response res;
    try {
      res = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw AiException('انتهت مهلة الاتصال. تحقّق من الإنترنت وحاول مجدّدًا.');
    } catch (_) {
      throw AiException('تعذّر الاتصال بالخدمة. تحقّق من الإنترنت والرابط.');
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw AiException('فشل التحقّق (مفتاح/سرّ غير صحيح). راجع الإعدادات.');
    }
    if (res.statusCode == 429) {
      throw AiException('تجاوزت حدّ الطلبات مؤقّتًا. انتظر قليلًا ثم أعد المحاولة.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AiException('خطأ من الخدمة (${res.statusCode}). حاول لاحقًا.');
    }

    return _extractText(res.bodyBytes);
  }

  /// يستخرج نصّ الردّ من جسم استجابة Anthropic: `content[].text`.
  String _extractText(List<int> bytes) {
    try {
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final content = json['content'];
      if (content is List) {
        final buf = StringBuffer();
        for (final part in content) {
          if (part is Map && part['type'] == 'text' && part['text'] is String) {
            buf.write(part['text']);
          }
        }
        final out = buf.toString().trim();
        if (out.isNotEmpty) return out;
      }
      throw const FormatException('no text');
    } catch (_) {
      throw AiException('تعذّر قراءة ردّ الخدمة.');
    }
  }
}
