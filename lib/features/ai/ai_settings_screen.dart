import 'package:flutter/material.dart';

import '../../services/ai_service.dart';

/// شاشة إعداد مساعد الذكاء الاصطناعي.
///
/// خياران (يكفي أحدهما):
/// • **رابط خدمة (وسيط)**: خادم وسيط يحتفظ بمفتاح المزوّد سرًّا — الأنسب للتطبيق
///   المنشور (لا يُخزَّن مفتاح على الجهاز).
/// • **مفتاح خاص**: مفتاح Anthropic الخاصّ بك، يُخزَّن آمنًا على الجهاز فقط.
class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final _endpoint = TextEditingController();
  final _secret = TextEditingController();
  final _apiKey = TextEditingController();
  final _model = TextEditingController();

  bool _loading = true;
  bool _hasKey = false;
  bool _showKey = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ai = AiService.instance;
    _endpoint.text = await ai.endpoint();
    _secret.text = await ai.proxySecret();
    _model.text = await ai.model();
    _hasKey = await ai.hasApiKey();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _endpoint.dispose();
    _secret.dispose();
    _apiKey.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // لا نمسّ المفتاح المخزَّن إن ترك الحقل فارغًا (كي لا نمحوه عن غير قصد).
    final keyInput = _apiKey.text.trim();
    await AiService.instance.saveConfig(
      endpoint: _endpoint.text,
      proxySecret: _secret.text,
      apiKey: keyInput.isEmpty ? null : keyInput,
      model: _model.text.trim().isEmpty ? AiService.defaultModel : _model.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('حُفظ إعداد المساعد')));
    Navigator.pop(context);
  }

  Future<void> _clearKey() async {
    await AiService.instance.saveConfig(apiKey: '');
    _apiKey.clear();
    if (mounted) setState(() => _hasKey = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('مساعد الذكاء الاصطناعي')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: scheme.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'يساعدك المساعد على تلخيص ملاحظاتك وإعادة صياغتها '
                          'وتدقيقها وتوسيعها. فعّله بإحدى الطريقتين أدناه.',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ---- الطريقة ١: رابط خدمة (وسيط) ----
                _sectionTitle(scheme, '١) رابط الخدمة (موصى به للنشر)'),
                const Text(
                  'خادم وسيط يحتفظ بمفتاح المزوّد سرًّا بعيدًا عن الجهاز. '
                  'يوجد ملف Cloudflare Worker جاهز مرفق مع التطبيق لنشره.',
                  style: TextStyle(fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _endpoint,
                  keyboardType: TextInputType.url,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'رابط الخدمة',
                    hintText: 'https://your-worker.workers.dev',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _secret,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'سرّ التطبيق (اختياريّ)',
                    hintText: 'إن ضبطت سرًّا مشتركًا في الوسيط',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),

                // ---- الطريقة ٢: مفتاح خاص (BYOK) ----
                _sectionTitle(scheme, '٢) مفتاح خاص (BYOK)'),
                const Text(
                  'مفتاح Anthropic الخاصّ بك، يُخزَّن آمنًا على هذا الجهاز فقط '
                  'ويُرسل مباشرةً إلى الخدمة. مناسب للاستخدام الشخصيّ.',
                  style: TextStyle(fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _apiKey,
                  obscureText: !_showKey,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: _hasKey ? 'تغيير المفتاح (محفوظ)' : 'المفتاح',
                    hintText: 'sk-ant-…',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.key),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(_showKey
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _showKey = !_showKey),
                        ),
                        if (_hasKey)
                          IconButton(
                            tooltip: 'حذف المفتاح المحفوظ',
                            icon: Icon(Icons.delete_outline,
                                color: scheme.error),
                            onPressed: _clearKey,
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),

                _sectionTitle(scheme, 'النموذج'),
                TextField(
                  controller: _model,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'اسم النموذج',
                    hintText: AiService.defaultModel,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.memory),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'الافتراضي هو الأحدث والأقدر. يمكنك اختيار نموذج أخفّ تكلفةً '
                  'إن رغبت.',
                  style: TextStyle(fontSize: 11),
                ),

                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ'),
                ),
              ],
            ),
    );
  }

  Widget _sectionTitle(ColorScheme scheme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: scheme.primary)),
      );
}
