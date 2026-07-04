import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/app_strings.dart';
import '../../data/models/password_entry.dart';

/// نموذج إدخال ملاحظة كلمات المرور: حقول منظّمة بالترتيب المطلوب + نسخ لكل حقل
/// (يظهر فقط حين يوجد نصّ) + مولّد + مؤشّر قوة + «العلاقات» (ربط بكلمات مرور أخرى).
class PasswordForm extends StatefulWidget {
  final PasswordEntry initial;
  final ValueChanged<PasswordEntry> onChanged;

  /// الترقيم التسلسلي = معرّف الملاحظة (null قبل أوّل حفظ).
  final int? noteId;

  /// يجلب (معرّف، عنوان) كل ملاحظات كلمات المرور — لاختيار العلاقات.
  final Future<List<(int, String)>> Function()? fetchRefs;

  /// فتح ملاحظة كلمة مرور مرتبطة بمعرّفها.
  final void Function(int id)? onOpenRelation;

  const PasswordForm({
    super.key,
    required this.initial,
    required this.onChanged,
    this.noteId,
    this.fetchRefs,
    this.onOpenRelation,
  });

  @override
  State<PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<PasswordForm> {
  late final TextEditingController _title;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _email;
  late final TextEditingController _website;
  late final TextEditingController _notes;
  late List<int> _relations;
  bool _obscure = true;
  Timer? _clearTimer;

  // عناوين ملاحظات كلمات المرور (لعرض العلاقات واختيارها).
  List<(int, String)> _allRefs = const [];
  Map<int, String> _titleById = const {};

  // سجلّ التراجع/الإعادة: لقطات للحالة كي يتراجع المستخدم عن تعديل خاطئ رغم
  // الحفظ التلقائي الفوريّ.
  final List<PasswordEntry> _history = [];
  int _histIndex = 0;
  Timer? _snapTimer;
  bool _restoring = false;

  // يمكن التراجع إن وُجدت لقطة أقدم، أو إن كان هناك تعديل حيّ غير مسجَّل بعد.
  bool get _canUndo =>
      _histIndex > 0 || _sig(_current()) != _sig(_history[_histIndex]);
  bool get _canRedo => _histIndex < _history.length - 1;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initial.title);
    _username = TextEditingController(text: widget.initial.username);
    _password = TextEditingController(text: widget.initial.password);
    _email = TextEditingController(text: widget.initial.email);
    _website = TextEditingController(text: widget.initial.website);
    _notes = TextEditingController(text: widget.initial.notes);
    _relations = List<int>.from(widget.initial.relations);
    _history.add(widget.initial); // اللقطة الأولى (الحالة المحمَّلة).
    _loadRefs();
  }

  Future<void> _loadRefs() async {
    final f = widget.fetchRefs;
    if (f == null) return;
    final refs = await f();
    if (!mounted) return;
    setState(() {
      _allRefs = refs;
      _titleById = {for (final r in refs) r.$1: r.$2};
    });
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    _snapTimer?.cancel();
    _title.dispose();
    _username.dispose();
    _password.dispose();
    _email.dispose();
    _website.dispose();
    _notes.dispose();
    super.dispose();
  }

  PasswordEntry _current() => PasswordEntry(
        title: _title.text,
        username: _username.text,
        password: _password.text,
        email: _email.text,
        website: _website.text,
        relations: List<int>.from(_relations),
        notes: _notes.text,
      );

  void _emit() {
    widget.onChanged(_current());
    if (!_restoring) {
      _scheduleSnapshot();
      // حدّث حالة زرَّي التراجع/الإعادة فورًا مع كل تعديل.
      if (mounted) setState(() {});
    }
  }

  /// توقيع نصّي للحالة (لمقارنة اللقطات دون تشفير عشوائيّ).
  static String _sig(PasswordEntry e) => [
        e.title,
        e.username,
        e.password,
        e.email,
        e.website,
        e.relations.join(','),
        e.notes,
      ].join('');

  /// يلتقط لقطة بعد توقّف التعديل بلحظة (كي لا تُسجَّل كل ضغطة على حدة).
  void _scheduleSnapshot() {
    _snapTimer?.cancel();
    _snapTimer = Timer(const Duration(milliseconds: 700), _recordSnapshot);
  }

  void _recordSnapshot() {
    final cur = _current();
    if (_sig(cur) == _sig(_history[_histIndex])) return; // بلا تغيير فعليّ.
    // اقطع أي «إعادة» سابقة ثم أضف اللقطة الجديدة.
    if (_histIndex < _history.length - 1) {
      _history.removeRange(_histIndex + 1, _history.length);
    }
    _history.add(cur);
    if (_history.length > 50) _history.removeAt(0); // حدّ أعلى للسجلّ.
    _histIndex = _history.length - 1;
    if (mounted) setState(() {});
  }

  void _restore(PasswordEntry e) {
    _restoring = true;
    _snapTimer?.cancel();
    setState(() {
      _title.text = e.title;
      _username.text = e.username;
      _password.text = e.password;
      _email.text = e.email;
      _website.text = e.website;
      _notes.text = e.notes;
      _relations = List<int>.from(e.relations);
    });
    widget.onChanged(e); // احفظ الحالة المستعادة فورًا.
    _restoring = false;
  }

  void _undo() {
    _snapTimer?.cancel();
    _recordSnapshot(); // ثبّت أي تعديل حيّ أولًا كي يُمكن التراجع عنه.
    if (_histIndex <= 0) return;
    _histIndex--;
    _restore(_history[_histIndex]);
  }

  void _redo() {
    if (!_canRedo) return;
    _snapTimer?.cancel();
    _histIndex++;
    _restore(_history[_histIndex]);
  }

  Future<void> _copy(String value) async {
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    _toast(S.of(context).t('pw_copied'));
  }

  /// نسخ آمن: يُمسح من الحافظة تلقائيًا بعد 30 ثانية.
  Future<void> _copySecure(String value) async {
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    _toast('${S.of(context).t('pw_copied')} — ${S.of(context).t('pw_clear_30')}');
    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(seconds: 30), () async {
      final data = await Clipboard.getData('text/plain');
      if (data?.text == value) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  void _generate() {
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const lower = 'abcdefghijkmnpqrstuvwxyz';
    const digits = '23456789';
    const symbols = '!@#\$%&*?-_=+';
    const all = upper + lower + digits + symbols;
    final rnd = Random.secure();
    const len = 16;
    final chars = <String>[
      upper[rnd.nextInt(upper.length)],
      lower[rnd.nextInt(lower.length)],
      digits[rnd.nextInt(digits.length)],
      symbols[rnd.nextInt(symbols.length)],
    ];
    for (var i = chars.length; i < len; i++) {
      chars.add(all[rnd.nextInt(all.length)]);
    }
    chars.shuffle(rnd);
    setState(() {
      _password.text = chars.join();
      _obscure = false;
    });
    _emit();
  }

  int _strength(String p) {
    if (p.isEmpty) return 0;
    var score = 0;
    if (p.length >= 8) score++;
    if (p.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'\d').hasMatch(p)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    return score.clamp(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // شريط تراجع/إعادة — لاستعادة قيمة سابقة رغم الحفظ التلقائي الفوريّ.
        Row(
          children: [
            IconButton.filledTonal(
              tooltip: 'تراجع',
              visualDensity: VisualDensity.compact,
              onPressed: _canUndo ? _undo : null,
              icon: const Icon(Icons.undo),
            ),
            const SizedBox(width: 6),
            IconButton.filledTonal(
              tooltip: 'إعادة',
              visualDensity: VisualDensity.compact,
              onPressed: _canRedo ? _redo : null,
              icon: const Icon(Icons.redo),
            ),
            const Spacer(),
            Icon(Icons.history, size: 16, color: scheme.outline),
            const SizedBox(width: 4),
            Text('تراجع/إعادة',
                style: TextStyle(fontSize: 12, color: scheme.outline)),
          ],
        ),
        _serialTile(),
        _field('العنوان', _title, Icons.badge_outlined),
        _field(s.t('pw_username'), _username, Icons.person_outline),
        _passwordField(s),
        _strengthBar(s),
        _field('البريد الإلكتروني', _email, Icons.alternate_email,
            keyboard: TextInputType.emailAddress),
        _field('الموقع الإلكتروني', _website, Icons.language,
            keyboard: TextInputType.url),
        _relationsSection(),
        _field(s.t('pw_notes'), _notes, Icons.notes, maxLines: 3),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.lock, size: 14, color: Theme.of(context).hintColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(s.t('pw_encrypted_hint'),
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ],
    );
  }

  /// الترقيم التسلسلي (معرّف الملاحظة) — للقراءة فقط، يُستخدم في «العلاقات».
  Widget _serialTile() {
    final scheme = Theme.of(context).colorScheme;
    final serial = widget.noteId != null ? '#${widget.noteId}' : 'يُنشأ بعد الحفظ';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withOpacity(0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.primary.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.tag, size: 20, color: scheme.primary),
            const SizedBox(width: 10),
            const Text('الترقيم التسلسلي',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(serial,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                    fontFeatures: const [])),
          ],
        ),
      ),
    );
  }

  /// عنوان صغير فوق الحقل (بدل العنوان العائم الذي كان يتداخل مع حافة البطاقة).
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 6),
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Theme.of(context).colorScheme.primary)),
      );

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {int maxLines = 1, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboard,
            onChanged: (_) => _emit(),
            decoration: InputDecoration(
              prefixIcon: Icon(icon),
              // زرّ النسخ يظهر فقط حين يحتوي الحقل على نصّ (لا نسخ لحقل فارغ).
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: ctrl,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: S.of(context).t('copy'),
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copy(ctrl.text),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField(S s) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(s.t('pw_password')),
          TextField(
            controller: _password,
            obscureText: _obscure,
            onChanged: (_) {
              setState(() {});
              _emit();
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.vpn_key),
              suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: s.t('pw_generate'),
                icon: const Icon(Icons.casino_outlined),
                onPressed: _generate,
              ),
              IconButton(
                tooltip: _obscure ? s.t('pw_show') : s.t('pw_hide'),
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              if (_password.text.isNotEmpty)
                IconButton(
                  tooltip: s.t('copy'),
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copySecure(_password.text),
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _strengthBar(S s) {
    if (_password.text.isEmpty) return const SizedBox(height: 4);
    final score = _strength(_password.text);
    const labels = ['ضعيفة جدًا', 'ضعيفة', 'متوسطة', 'جيدة', 'قوية'];
    const colors = [
      Color(0xFFE53935),
      Color(0xFFFB8C00),
      Color(0xFFFDD835),
      Color(0xFF7CB342),
      Color(0xFF2E7D32),
    ];
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 6, top: 2),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (score + 1) / 5,
                minHeight: 6,
                backgroundColor: Theme.of(context).dividerColor,
                color: colors[score],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(labels[score],
              style: TextStyle(fontSize: 12, color: colors[score])),
        ],
      ),
    );
  }

  // ---------------- العلاقات ----------------

  Widget _relationsSection() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hub_outlined, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              const Text('العلاقات',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: _pickRelation,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة علاقة'),
              ),
            ],
          ),
          if (_relations.isEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4, bottom: 4),
              child: Text(
                'اربط كلمات مرور ذات علاقة (مثل البريد الذي سُجِّل به هذا الحساب).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            for (final id in _relations)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Material(
                  color: scheme.primaryContainer.withOpacity(0.30),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: widget.onOpenRelation == null
                        ? null
                        : () => widget.onOpenRelation!(id),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: scheme.primary,
                            child: Text('#$id',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.white)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_titleById[id] ?? 'كلمة مرور #$id',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (widget.onOpenRelation != null)
                            Icon(Icons.open_in_new,
                                size: 18, color: scheme.primary),
                          IconButton(
                            tooltip: 'حذف العلاقة',
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.close, color: scheme.error),
                            onPressed: () => _removeRelation(id),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  /// حذف علاقة برسالة تأكيد (كي لا تُحذف بلمسة عابرة).
  Future<void> _removeRelation(int id) async {
    final title = _titleById[id] ?? 'كلمة مرور #$id';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.link_off),
        title: const Text('حذف العلاقة؟'),
        content: Text('إزالة الربط مع «$title». يمكنك إعادة إضافته لاحقًا.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        _relations.remove(id);
        _emit();
      });
    }
  }

  Future<void> _pickRelation() async {
    // الخيارات: كل كلمات المرور عدا هذه الملاحظة وما ارتبط سابقًا.
    final options = _allRefs
        .where((r) => r.$1 != widget.noteId && !_relations.contains(r.$1))
        .toList();
    if (options.isEmpty) {
      _toast('لا توجد كلمات مرور أخرى لربطها');
      return;
    }
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text('اختر كلمة مرور لربطها',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              for (final r in options)
                ListTile(
                  leading: CircleAvatar(child: Text('#${r.$1}',
                      style: const TextStyle(fontSize: 11))),
                  title: Text(r.$2),
                  onTap: () => Navigator.pop(ctx, r.$1),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _relations.add(picked);
        _emit();
      });
    }
  }
}
