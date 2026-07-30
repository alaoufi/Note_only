import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/ai_service.dart';
import '../editor/rich_text_field.dart';
import 'ai_settings_screen.dart';

/// يفتح ورقة مساعد الذكاء الاصطناعي على محرّر النصّ الغني.
///
/// يعمل على **النصّ المحدّد** إن وُجد تحديد، وإلا على **كامل الملاحظة**. يُظهر
/// النتيجة مع خيارات: استبدال / إدراج بعده / نسخ / إعادة.
Future<void> showAiAssistant(
    BuildContext context, RichTextController controller) async {
  final q = controller.quill;
  final plain = q.document.toPlainText();
  final sel = q.selection;

  int start;
  int end;
  if (sel.isValid && !sel.isCollapsed) {
    start = sel.start.clamp(0, plain.length);
    end = sel.end.clamp(start, plain.length);
  } else {
    // كامل الملاحظة (نتجنّب فاصل السطر الأخير الذي يضيفه Quill دائمًا).
    start = 0;
    end = plain.isNotEmpty ? plain.length - 1 : 0;
  }
  final source = plain.substring(start, end).trim();

  if (source.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('اكتب نصًّا أولًا ليعمل عليه المساعد')));
    return;
  }
  final onSelection = sel.isValid && !sel.isCollapsed;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _AiSheet(
      controller: controller,
      source: source,
      rangeStart: start,
      rangeEnd: end,
      onSelection: onSelection,
    ),
  );
}

class _AiSheet extends StatefulWidget {
  final RichTextController controller;
  final String source;
  final int rangeStart;
  final int rangeEnd;
  final bool onSelection;

  const _AiSheet({
    required this.controller,
    required this.source,
    required this.rangeStart,
    required this.rangeEnd,
    required this.onSelection,
  });

  @override
  State<_AiSheet> createState() => _AiSheetState();
}

enum _Phase { pick, running, result, error }

class _AiSheetState extends State<_AiSheet> {
  _Phase _phase = _Phase.pick;
  AiAction? _action;
  String _result = '';
  String _error = '';
  final _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(AiAction action, {String? instruction}) async {
    setState(() {
      _action = action;
      _phase = _Phase.running;
    });
    try {
      final out = await AiService.instance
          .run(action, widget.source, instruction: instruction);
      if (!mounted) return;
      setState(() {
        _result = out;
        _phase = _Phase.result;
      });
    } on AiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _phase = _Phase.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'حدث خطأ غير متوقّع.';
        _phase = _Phase.error;
      });
    }
  }

  void _applyReplace() {
    final q = widget.controller.quill;
    final len = widget.rangeEnd - widget.rangeStart;
    q.replaceText(
      widget.rangeStart,
      len,
      _result,
      TextSelection.collapsed(offset: widget.rangeStart + _result.length),
    );
    _done('تمّ الاستبدال');
  }

  void _applyInsertAfter() {
    final q = widget.controller.quill;
    final insert = '\n$_result';
    q.replaceText(
      widget.rangeEnd,
      0,
      insert,
      TextSelection.collapsed(offset: widget.rangeEnd + insert.length),
    );
    _done('تمّت الإضافة');
  }

  void _done(String msg) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1200)));
  }

  Future<void> _askCustom() async {
    _customCtrl.clear();
    final instruction = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعليمات مخصّصة'),
        content: TextField(
          controller: _customCtrl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'مثال: حوّل النصّ إلى نقاط، أو ترجمه للإنجليزية…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _customCtrl.text.trim()),
            child: const Text('تنفيذ'),
          ),
        ],
      ),
    );
    if (instruction != null && instruction.isNotEmpty) {
      await _run(AiAction.custom, instruction: instruction);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: scheme.primary),
              const SizedBox(width: 8),
              const Text('مساعد الذكاء الاصطناعي',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const Spacer(),
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(widget.onSelection ? 'النص المحدّد' : 'كامل الملاحظة',
                    style: const TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(child: _buildPhase(scheme)),
        ],
      ),
    );
  }

  Widget _buildPhase(ColorScheme scheme) {
    switch (_phase) {
      case _Phase.pick:
        return _buildPicker(scheme);
      case _Phase.running:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('${_action?.label ?? ''}…',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ),
        );
      case _Phase.result:
        return _buildResult(scheme);
      case _Phase.error:
        return _buildError(scheme);
    }
  }

  Widget _buildPicker(ColorScheme scheme) {
    Widget tile(AiAction a, IconData icon) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            child: Icon(icon, color: scheme.onPrimaryContainer, size: 20),
          ),
          title: Text(a.label,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(a.hint, style: const TextStyle(fontSize: 12)),
          onTap: () => a == AiAction.custom ? _askCustom() : _run(a),
        );
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tile(AiAction.summarize, Icons.short_text),
          tile(AiAction.rewrite, Icons.auto_fix_high),
          tile(AiAction.proofread, Icons.spellcheck),
          tile(AiAction.expand, Icons.expand),
          tile(AiAction.continueWriting, Icons.edit_note),
          tile(AiAction.custom, Icons.tune),
        ],
      ),
    );
  }

  Widget _buildResult(ColorScheme scheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_action?.label ?? '',
            style: TextStyle(
                color: scheme.primary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Flexible(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 280),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: SelectableText(_result,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 15, height: 1.6)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _applyReplace,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('استبدال'),
            ),
            OutlinedButton.icon(
              onPressed: _applyInsertAfter,
              icon: const Icon(Icons.playlist_add, size: 18),
              label: const Text('إدراج بعده'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _result));
                _done('نُسخ إلى الحافظة');
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('نسخ'),
            ),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _phase = _Phase.pick),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('إجراء آخر'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError(ColorScheme scheme) {
    final needsSetup =
        _error.contains('الإعدادات') || _error.contains('يُفعّل');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: scheme.error, size: 40),
          const SizedBox(height: 12),
          Text(_error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (needsSetup)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AiSettingsScreen()));
                  },
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('الإعدادات'),
                )
              else
                FilledButton.icon(
                  onPressed: () =>
                      setState(() => _phase = _Phase.pick),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('إعادة المحاولة'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
