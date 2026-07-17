import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/text/arabic_search.dart';
import '../../core/text/line_direction.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/note_gradient.dart';
import '../../data/models/checklist_item.dart';
import '../../data/models/enums.dart';
import '../../data/models/note.dart';
import '../../data/models/note_attachment.dart';
import '../../services/file_service.dart';
import 'attachment_viewer.dart';
import '../../data/models/password_entry.dart';
import '../../data/models/treatment_entry.dart';
import '../../services/pdf_export_service.dart';
import '../../services/word_export_service.dart';
import '../../services/secure_screen.dart';
import '../../services/vault_service.dart';
import 'password_form.dart';
import 'treatment_form.dart';
import '../../widgets/color_picker_sheet.dart';
import '../../widgets/note_actions.dart';
import '../../widgets/paper_background.dart';
import '../drawing/drawing_screen.dart';
import '../home/notes_provider.dart';
import '../security/note_unlock.dart';
import '../settings/settings_provider.dart';
import '../../services/notification_service.dart';
import 'editor_attachments.dart';
import 'rich_text_field.dart';

/// محرّر الملاحظة لكل الأنواع، مع حفظ تلقائي أثناء الكتابة.
class NoteEditorScreen extends StatefulWidget {
  final int? noteId;
  final NoteType initialType;
  final int? initialCategoryId;

  /// عند فتح «قائمة مهام» جديدة: هل يبدأ السطر الأول كمهمة (بمربع) أم نصًّا عاديًّا.
  final bool startAsTask;

  /// عند الفتح من نتائج البحث: نصّ البحث — يُفتح شريط «بحث داخل الملاحظة» مسبقًا
  /// وينتقل مباشرةً إلى أول تطابق داخل المتن.
  final String? initialFind;

  const NoteEditorScreen({
    super.key,
    this.noteId,
    this.initialType = NoteType.text,
    this.initialCategoryId,
    this.startAsTask = true,
    this.initialFind,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _contentFocus = FocusNode(); // لتظليل نتائج البحث في تعليق الوسائط

  late Note _note;
  List<ChecklistItem> _checklist = [];
  final List<TextEditingController> _itemCtrls = [];
  final List<FocusNode> _itemFocus = [];
  PasswordEntry _passwordEntry = const PasswordEntry();
  TreatmentEntry _treatmentEntry = const TreatmentEntry();
  String _richContent = ''; // محتوى النص الغني (Delta JSON) لنوع النص
  RichTextController? _richCtrl; // وحدة تحكّم النص الغني (لنوع النص فقط)

  // ---- بحث داخل الملاحظة (نص فقط) ----
  bool _findVisible = false;
  final _findCtrl = TextEditingController();
  final _findFocus = FocusNode();
  List<List<int>> _findMatches = const []; // أزواج [start, end] بإحداثيات المستند
  int _findIndex = 0;
  bool _findJumped = false; // هل انتقلنا لتطابق بعدُ لمصطلح البحث الحالي؟

  Timer? _debounce;
  Color _fgColor = Colors.black87; // لون نص المتن المناسب للخلفية الحالية
  bool _loaded = false;
  bool _dirty = false;
  bool _drawingPrompted = false;
  bool _secured = false;
  bool _deleted = false; // نُقلت للمهملات ⇒ لا تُحفظ ثانيةً عند الإغلاق
  // هل حملت الملاحظة محتوًى حقيقيًّا (عند التحميل أو أثناء الجلسة)؟ نميّز به بين
  // ملاحظة أُفرِغت بعد محتوى (⇒ للسلّة، قابلة للاسترجاع) وأخرى لم تحوِ شيئًا قطّ
  // (⇒ حذف نهائيّ، مثل ملاحظة أُنشئت مؤقّتًا لفتح قائمة).
  bool _hadRealContent = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<NotesProvider>();
    await VaultService.instance.ensureKey();
    if (widget.noteId != null) {
      final n = await provider.notes.getNote(widget.noteId!);
      if (n != null) {
        _note = n;
        _titleCtrl.text = n.title;
        _contentCtrl.text = n.content;
        if (n.type == NoteType.checklist) {
          _checklist = await provider.notes.getChecklist(n.id!);
          if (_checklist.isEmpty) _checklist = [ChecklistItem(noteId: n.id!, text: '')];
          _rebuildItemCtrls();
        } else if (n.type == NoteType.password) {
          _passwordEntry = PasswordEntry.fromStoredJson(n.content);
        } else if (n.type == NoteType.treatment) {
          _treatmentEntry = TreatmentEntry.fromStoredJson(n.content);
        } else if (n.type == NoteType.text) {
          _richContent = n.content;
        }
      } else {
        _note = Note.create(type: widget.initialType);
      }
    } else {
      // ملاحظة جديدة: طبّق الافتراضي (لون الخلفية ونمط الصفحة) من الإعدادات.
      final settings = context.read<SettingsProvider>();
      _note = Note.create(
              type: widget.initialType, categoryId: widget.initialCategoryId)
          .copyWith(
        color: settings.defaultNoteColor,
        clearColor: settings.defaultNoteColor == null,
        bgStyle: settings.defaultBgStyle,
        gradient: settings.defaultGradient,
      );
      if (_note.type == NoteType.checklist) {
        _checklist = [
          ChecklistItem(noteId: 0, text: '', isTask: widget.startAsTask)
        ];
        _rebuildItemCtrls();
      } else if (_note.type == NoteType.password) {
        // ملاحظات كلمات المرور مقفلة افتراضيًا (تتطلب فتح القفل لعرضها).
        _note = _note.copyWith(isLocked: true);
      }
    }
    // وحدة تحكّم النص الغني (لنوع النص) — تُهيّأ بعد معرفة المحتوى.
    if (_note.type == NoteType.text) {
      _richCtrl = RichTextController(_richContent, (json) {
        _richContent = json;
        _onChanged();
      });
    }

    // قد تُغلَق الشاشة أثناء التحميل غير المتزامن أعلاه؛ لا نلمس الحالة بعد التخلّص.
    if (!mounted) return;
    setState(() => _loaded = true);
    // ملاحظة مُحمّلة بمحتوى ⇒ احفظ أنها حملت محتوًى حقيقيًّا (لتذهب للسلّة لو أُفرِغت).
    _hadRealContent = !_isCurrentlyEmpty();

    _titleCtrl.addListener(_onChanged);
    _contentCtrl.addListener(_onChanged);

    // منع التصوير للملاحظات الحسّاسة (سرية/كلمات مرور).
    if (_note.type == NoteType.password || _note.isLocked) {
      _secured = true;
      SecureScreen.enable();
    }

    // فُتحت من نتائج البحث ⇒ افتح شريط البحث داخل المتن وانتقل لأول تطابق.
    // نمهل المحرّر لحظةً كي يكتمل بناؤه وتمريره قبل القفز إلى التطابق.
    final find = widget.initialFind?.trim() ?? '';
    if (find.isNotEmpty && _canFindInNote) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        if (mounted) _openFind(find);
      });
    }
  }

  void _rebuildItemCtrls() {
    for (final c in _itemCtrls) {
      c.dispose();
    }
    for (final f in _itemFocus) {
      f.dispose();
    }
    _itemCtrls.clear();
    _itemFocus.clear();
    for (final item in _checklist) {
      _itemCtrls.add(TextEditingController(text: item.text));
      _itemFocus.add(FocusNode());
    }
  }

  /// إدراج عنصر جديد بعد [i] مباشرةً والانتقال إليه (عند ضغط Enter).
  /// يرث نوع السطر الحالي (مهمة/نص) كما في تطبيقات المذكرات.
  /// [text]: النصّ المنقول لما بعد المؤشّر عند تقسيم سطر (وإلا سطر فارغ).
  void _addItemAfter(int i, {String text = ''}) {
    final inheritTask =
        (i >= 0 && i < _checklist.length) ? _checklist[i].isTask : true;
    setState(() {
      _checklist.insert(
          i + 1,
          ChecklistItem(
              noteId: _note.id ?? 0, text: text, isTask: inheritTask));
      _itemCtrls.insert(i + 1, TextEditingController(text: text));
      _itemFocus.insert(i + 1, FocusNode());
    });
    _onChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (i + 1 < _itemFocus.length) {
        _itemFocus[i + 1].requestFocus();
        // المؤشّر في بداية النص المنقول (حيث ضُغط Enter).
        _itemCtrls[i + 1].selection =
            const TextSelection.collapsed(offset: 0);
      }
    });
  }

  void _onChanged() {
    _dirty = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _save);
  }

  // ============ بحث داخل الملاحظة (نصّ + تعليق الوسائط) ============

  /// أنواع الوسائط التي لها حقل تعليق نصّي قابل للبحث.
  bool get _isMediaCaptionType =>
      _note.type == NoteType.image ||
      _note.type == NoteType.audio ||
      _note.type == NoteType.pdf ||
      _note.type == NoteType.drawing;

  /// هل يدعم البحث داخل هذه الملاحظة؟ (نصّ غنيّ، أو وسيط ذو تعليق.)
  bool get _canFindInNote =>
      (_note.type == NoteType.text && _richCtrl != null) || _isMediaCaptionType;

  /// النصّ المصدر للبحث حسب النوع.
  String _findSourceText() => _note.type == NoteType.text
      ? (_richCtrl?.plainText ?? '')
      : _contentCtrl.text;

  /// يفتح شريط البحث داخل المتن. [initial] يُملأ به الحقل وينتقل لأول تطابق.
  void _openFind([String? initial]) {
    if (!_canFindInNote) return;
    setState(() => _findVisible = true);
    if (initial != null && initial.trim().isNotEmpty) {
      _findCtrl.text = initial.trim();
      _recountFind();
      _findNext(); // انتقل لأول تطابق وظلّله ومرّر العرض إليه.
    } else {
      // ركّز حقل البحث ليكتب المستخدم مباشرةً.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _findFocus.requestFocus());
    }
  }

  void _closeFind() {
    setState(() {
      _findVisible = false;
      _findMatches = const [];
      _findIndex = 0;
      _findJumped = false;
    });
  }

  /// يعيد حساب مواضع التطابق للمصطلح الحالي (يُستدعى أثناء الكتابة). لا يُغيّر
  /// التحديد ولا يخطف التركيز — كي يكمل المستخدم الكتابة في حقل البحث بسلاسة.
  void _recountFind() {
    setState(() {
      _findMatches = findArabicMatches(_findSourceText(), _findCtrl.text);
      _findIndex = 0;
      _findJumped = false;
    });
  }

  /// التطابق التالي (سهم أسفل/Enter). أول ضغطة بعد الكتابة تنتقل للأول.
  void _findNext() {
    if (_findMatches.isEmpty) return;
    _gotoMatch(_findJumped ? _findIndex + 1 : 0);
  }

  /// التطابق السابق (سهم أعلى).
  void _findPrev() {
    if (_findMatches.isEmpty) return;
    _gotoMatch(_findJumped ? _findIndex - 1 : 0);
  }

  /// ينتقل للتطابق رقم [i] (مع الالتفاف) ويُظلّله ويُمرّر العرض إليه.
  void _gotoMatch(int i) {
    if (_findMatches.isEmpty) return;
    final len = _findMatches.length;
    final idx = ((i % len) + len) % len; // التفاف للأمام/الخلف
    setState(() {
      _findIndex = idx;
      _findJumped = true;
    });
    final r = _findMatches[idx];
    if (_note.type == NoteType.text && _richCtrl != null) {
      _richCtrl!.selectMatch(r[0], r[1] - r[0]);
    } else {
      // وسيط ذو تعليق: نحدّد المطابقة في حقل النصّ ونركّزه لتظهر مظلَّلة.
      final maxLen = _contentCtrl.text.length;
      final start = r[0].clamp(0, maxLen);
      final end = r[1].clamp(start, maxLen);
      _contentCtrl.selection =
          TextSelection(baseOffset: start, extentOffset: end);
      _contentFocus.requestFocus();
    }
  }

  /// شريط «بحث داخل الملاحظة»: حقل + عدّاد نتائج + سهما تنقّل + إغلاق.
  Widget _buildFindBar(S s) {
    final scheme = Theme.of(context).colorScheme;
    final has = _findMatches.isNotEmpty;
    final counter = _findCtrl.text.trim().isEmpty
        ? ''
        : has
            ? '${_findIndex + 1}/${_findMatches.length}'
            : s.t('no_results');
    return Material(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _findCtrl,
                focusNode: _findFocus,
                textDirection: lineDirection(_findCtrl.text),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: s.t('find_in_note'),
                ),
                onChanged: (_) => _recountFind(),
                onSubmitted: (_) => _findNext(),
              ),
            ),
            Text(counter,
                style: TextStyle(
                    color: has ? scheme.onSurfaceVariant : scheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            IconButton(
              tooltip: s.t('find_prev'),
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.keyboard_arrow_up),
              onPressed: has ? _findPrev : null,
            ),
            IconButton(
              tooltip: s.t('find_next'),
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: has ? _findNext : null,
            ),
            IconButton(
              tooltip: s.t('close'),
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close),
              onPressed: _closeFind,
            ),
          ],
        ),
      ),
    );
  }

  String _checklistToContent() {
    return _checklist
        .map((i) => i.isTask
            ? '${i.isDone ? '[x]' : '[ ]'} ${i.text}'
            : i.text)
        .where((l) => l.trim().isNotEmpty)
        .join('\n');
  }

  // ===================== تذكير بسيط للملاحظة (يوم + وقت) =====================

  bool get _hasActiveReminder =>
      _note.reminderAt != null && _note.reminderAt!.isAfter(DateTime.now());

  String _fmtReminder(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _onReminderPressed() async {
    if (!_hasActiveReminder) {
      await _pickReminder();
      return;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading:
                const Icon(Icons.notifications_active, color: Colors.amber),
            title: Text('تذكير: ${_fmtReminder(_note.reminderAt!)}'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.edit_calendar_outlined),
            title: const Text('تغيير الوقت'),
            onTap: () => Navigator.pop(ctx, 'change'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_off_outlined,
                color: Colors.red),
            title: const Text('إزالة التذكير'),
            onTap: () => Navigator.pop(ctx, 'remove'),
          ),
        ]),
      ),
    );
    if (choice == 'change') await _pickReminder();
    if (choice == 'remove') await _removeReminder();
  }

  Future<void> _pickReminder() async {
    await _ensureSaved();
    if (!mounted) return;
    final now = DateTime.now();
    final existing = _note.reminderAt;
    final date = await showDatePicker(
      context: context,
      initialDate: (existing != null && existing.isAfter(now)) ? existing : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 366 * 5)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay.fromDateTime(existing ?? now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;
    final when =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!when.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اختر وقتًا في المستقبل')));
      return;
    }
    setState(() => _note = _note.copyWith(reminderAt: when));
    _dirty = true;
    await _save(force: true);
    final body = _note.type == NoteType.text
        ? richToPlainText(_note.content)
        : _note.title;
    if (_note.id != null) {
      await NotificationService.instance
          .scheduleNoteReminder(_note.id!, when, _note.title, body);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('سيُذكّرك في ${_fmtReminder(when)}')));
    }
  }

  Future<void> _removeReminder() async {
    final id = _note.id;
    setState(() => _note = _note.copyWith(clearReminder: true));
    _dirty = true;
    await _save(force: true);
    if (id != null) await NotificationService.instance.cancelNoteReminder(id);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('أُزيل التذكير')));
    }
  }

  /// حذف الوسيط (صورة/صوت/PDF/رسم) من الملاحظة مع تأكيد — تبقى الملاحظة ونصّها.
  Future<void> _removeMedia(
      {bool image = false,
      bool audio = false,
      bool pdf = false,
      bool drawing = false,
      required String label}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: Text('حذف $label؟'),
        content: Text('سيُحذف $label من الملاحظة (يبقى النصّ). لا يمكن التراجع.'),
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
    if (ok != true) return;
    setState(() => _note = _note.copyWith(
          clearImage: image,
          clearAudio: audio,
          clearPdf: pdf,
          clearDrawing: drawing,
        ));
    _dirty = true;
    await _ensureSaved();
    await _save(force: true);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('حُذف $label')));
    }
  }

  Future<void> _save({bool force = false}) async {
    if (!_loaded || _deleted) return;
    final provider = context.read<NotesProvider>();

    // لملاحظات كلمات المرور/العلاج: العنوان حقلٌ داخل النموذج فنستمدّه منه.
    final title = switch (_note.type) {
      NoteType.password => _passwordEntry.title,
      NoteType.treatment => _treatmentEntry.displayTitle,
      _ => _titleCtrl.text,
    };
    var content = _contentCtrl.text;
    var emptyStructured = false;
    var emptyRich = false;
    if (_note.type == NoteType.checklist) {
      // زامن النصوص من الحقول.
      for (var i = 0; i < _checklist.length && i < _itemCtrls.length; i++) {
        _checklist[i] = _checklist[i].copyWith(text: _itemCtrls[i].text);
      }
      content = _checklistToContent();
    } else if (_note.type == NoteType.text) {
      content = _richContent;
      emptyRich = richToPlainText(_richContent).trim().isEmpty;
    } else if (_note.type == NoteType.password) {
      emptyStructured = _passwordEntry.isEmpty;
      content = _passwordEntry.toStoredJson();
    } else if (_note.type == NoteType.treatment) {
      emptyStructured = _treatmentEntry.isEmpty;
      content = _treatmentEntry.toStoredJson();
    }

    final candidate = _note.copyWith(
      title: title,
      content: content,
      updatedAt: DateTime.now(),
    );

    // لا تحفظ ملاحظة فارغة تمامًا.
    final bool isEmpty;
    if (_note.type == NoteType.password ||
        _note.type == NoteType.treatment) {
      isEmpty = title.trim().isEmpty && emptyStructured;
    } else if (_note.type == NoteType.text) {
      isEmpty = title.trim().isEmpty && emptyRich;
    } else {
      isEmpty = candidate.isEmpty;
    }
    if (isEmpty && !force) return;
    if (!isEmpty) _hadRealContent = true; // حملت محتوًى حقيقيًّا في هذه الجلسة.

    // أثناء التحرير لا نُعيد تحميل كامل القائمة (مئات الملاحظات) مع كل حفظ
    // مؤجَّل — هذا كان سبب البطء عند كتابة سطر جديد. التحديث يحدث مرّة واحدة
    // في الخلفية عند إغلاق المحرّر (انظر [_onWillPop]).
    final id = await provider.saveNote(
      candidate,
      checklist: _note.type == NoteType.checklist ? _checklist : null,
      reload: false,
    );
    final wasNew = _note.id == null;
    _note = candidate.copyWith(id: id);
    _dirty = false;
    // بعد أوّل حفظ يظهر «الترقيم التسلسلي» (المعرّف) في نموذج كلمة المرور.
    if (wasNew && _note.type == NoteType.password && mounted) {
      setState(() {});
    }
  }

  Future<bool> _onWillPop() async {
    _debounce?.cancel();
    // التقط آخر محتوى حيّ من المحرّر (قد يكون مؤقّت الحفظ المؤجَّل لم ينقضِ بعد).
    if (_richCtrl != null) _richContent = _richCtrl!.currentContent;
    final provider = context.read<NotesProvider>();
    if (!_deleted) {
      // لا نُبقي ملاحظة فارغة (كُتب فيها ثم مُحي، أو أُنشئت مؤقّتًا لفتح قائمة):
      // إن كانت محفوظة سابقًا نحذفها نهائيًّا، وإن كانت جديدة لا نُنشئها.
      if (_isCurrentlyEmpty()) {
        if (_note.id != null) {
          // كانت تحوي محتوًى ثم أُفرِغت ⇒ للسلّة (قابلة للاسترجاع تفاديًا لفقد
          // بالخطأ). لم تحوِ محتوًى قطّ (أُنشئت مؤقّتًا) ⇒ حذف نهائيّ بلا أثر.
          if (_hadRealContent) {
            await provider.moveToTrash(_note);
          } else {
            await provider.deleteForever(_note);
          }
        }
        _deleted = true;
      } else if (_dirty || _note.id == null) {
        await _save();
      }
    }
    // حدّث القائمة مرّة واحدة في الخلفية (بصمت، بلا وميض تحميل) كي لا يتأخّر
    // الرجوع للملاحظات ويظلّ الانتقال سلسًا.
    unawaited(provider.refresh(silent: true));
    return true;
  }

  /// هل الملاحظة فارغة فعليًّا الآن (من حالة المحرّر الحيّة)؟ فارغة = بلا عنوان،
  /// وبلا مرفق (صورة/صوت/PDF/رسم)، وبلا محتوى حسب نوعها. تُستخدم كي لا نحفظ/نُبقي
  /// ملاحظة لا كتابة فيها.
  bool _isCurrentlyEmpty() {
    if (_titleCtrl.text.trim().isNotEmpty) return false;
    if (_note.imagePath != null ||
        _note.audioPath != null ||
        _note.pdfPath != null ||
        _note.drawingPath != null) {
      return false;
    }
    switch (_note.type) {
      case NoteType.password:
        return _passwordEntry.isEmpty;
      case NoteType.treatment:
        return _treatmentEntry.isEmpty;
      case NoteType.checklist:
        return !_itemCtrls.any((c) => c.text.trim().isNotEmpty);
      case NoteType.text:
        // النصّ الحيّ من المحرّر (لا _richContent المؤجَّل ~600ms) كي يُلتقط
        // الحذف فورًا عند الخروج السريع.
        final live = _richCtrl != null
            ? _richCtrl!.plainText
            : richToPlainText(_richContent);
        return live.trim().isEmpty;
      default:
        return _contentCtrl.text.trim().isEmpty;
    }
  }

  @override
  void dispose() {
    if (_secured) SecureScreen.disable();
    _debounce?.cancel();
    _richCtrl?.dispose();
    _findCtrl.dispose();
    _findFocus.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _contentFocus.dispose();
    for (final c in _itemCtrls) {
      c.dispose();
    }
    for (final f in _itemFocus) {
      f.dispose();
    }
    super.dispose();
  }

  // ---- المرفقات ----

  Future<void> _ensureSaved() async {
    if (_note.id == null) await _save(force: true);
  }

  Future<void> _attachImage() async {
    final path = await EditorAttachments.pickImage(context);
    if (path == null) return;
    setState(() => _note = _note.copyWith(imagePath: path));
    _dirty = true;
    await _save(force: true);
  }

  Future<void> _attachPdf() async {
    final path = await EditorAttachments.pickPdf();
    if (path == null) return;
    setState(() => _note = _note.copyWith(pdfPath: path));
    _dirty = true;
    await _save(force: true);
  }

  /// تصدير الملاحظة (النص الغني) إلى PDF مع الحفاظ على التنسيق.
  Future<void> _exportPdf() async {
    final messenger = ScaffoldMessenger.of(context);
    // احفظ آخر تعديل أولًا كي يُصدَّر المحتوى المحدّث.
    await _save(force: true);
    final exportNote = _note.copyWith(content: _richContent);
    messenger.showSnackBar(const SnackBar(
        content: Text('جارٍ تجهيز ملف PDF…'),
        duration: Duration(seconds: 1)));
    try {
      await PdfExportService.exportNote(exportNote);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('تعذّر التصدير: $e')));
    }
  }

  /// تصدير الملاحظة إلى مستند Word‏ (.doc) مع الحفاظ على التنسيق.
  Future<void> _exportWord() async {
    final messenger = ScaffoldMessenger.of(context);
    await _save(force: true);
    final exportNote = _note.copyWith(content: _richContent);
    messenger.showSnackBar(const SnackBar(
        content: Text('جارٍ تجهيز ملف Word…'),
        duration: Duration(seconds: 1)));
    try {
      await WordExportService.exportNote(exportNote);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('تعذّر التصدير: $e')));
    }
  }

  Future<void> _editDrawing() async {
    await _ensureSaved();
    if (!mounted) return;
    final path = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => DrawingScreen(existingPath: _note.drawingPath),
      ),
    );
    if (path != null) {
      setState(() => _note = _note.copyWith(drawingPath: path));
      _dirty = true;
      await _save(force: true);
    }
  }

  void _onDrawingSetup() {
    // النوع رسم لكن لا يوجد رسم بعد: افتح لوحة الرسم مرة واحدة فقط.
    if (_drawingPrompted) return;
    if (_note.type == NoteType.drawing && _note.drawingPath == null) {
      _drawingPrompted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _editDrawing());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _onDrawingSetup();

    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.resolveNoteColor(_note.color, isDark);
    final grad = NoteGradient.parse(_note.gradient);
    final onBg = grad != null
        ? grad.onColor
        : (ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
            ? Colors.white
            : Colors.black87);
    _fgColor = onBg;

    final scaffold = Scaffold(
      backgroundColor: grad != null ? Colors.transparent : bg,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
          backgroundColor: grad != null ? Colors.transparent : bg,
          actions: [
            IconButton(
              tooltip: _note.isPinned ? s.t('unpin') : s.t('pin'),
              icon: Icon(_note.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              onPressed: () async {
                await _ensureSaved();
                setState(() => _note = _note.copyWith(isPinned: !_note.isPinned));
                // togglePin يقلب القيمة الممرَّرة (is_pinned: x ? 0 : 1)، لذا نمرّر
                // القيمة *القديمة* (نفي مزدوج) كي يصبح الناتج مطابقًا للواجهة. لا تبسّطه.
                await context.read<NotesProvider>().togglePin(
                    _note.copyWith(isPinned: !_note.isPinned));
              },
            ),
            IconButton(
              tooltip: s.t('color'),
              icon: const Icon(Icons.palette_outlined),
              onPressed: () async {
                final res = await showColorPicker(context, _note.color,
                    currentStyle: _note.bgStyle,
                    currentGradient: _note.gradient,
                    currentOnLine: _note.ruleOnLine ?? settings.ruleOnLine,
                    currentThickness:
                        _note.ruleThickness ?? settings.ruleThickness,
                    currentOpacity: _note.ruleOpacity ?? settings.ruleOpacity,
                    currentLineHeight:
                        _note.ruleLineHeight ?? settings.noteLineHeight,
                    defaultColor: settings.defaultNoteColor,
                    defaultGradient: settings.defaultGradient);
                if (res != null) {
                  setState(() => _note = _note.copyWith(
                        color: res.value,
                        clearColor: res.value == null,
                        bgStyle: res.bgStyle,
                        gradient: res.gradient,
                        clearGradient: res.gradient == null,
                        ruleOnLine: res.ruleOnLine,
                        ruleThickness: res.ruleThickness,
                        ruleOpacity: res.ruleOpacity,
                        ruleLineHeight: res.ruleLineHeight,
                      ));
                  _dirty = true;
                  await _ensureSaved();
                  await _save(force: true);
                }
              },
            ),
            IconButton(
              tooltip: _note.isFavorite ? s.t('unfavorite') : s.t('favorite'),
              icon: Icon(_note.isFavorite ? Icons.star : Icons.star_border,
                  color: _note.isFavorite ? Colors.amber : null),
              onPressed: () async {
                await _ensureSaved();
                final updated = _note.copyWith(isFavorite: !_note.isFavorite);
                setState(() => _note = updated);
                // toggleFavorite يقلب القيمة الممرَّرة، فنمرّر القيمة القديمة (نفي
                // مزدوج) ليطابق الناتج الواجهة. مثل togglePin أعلاه — لا تبسّطه.
                await context.read<NotesProvider>().toggleFavorite(
                    _note.copyWith(isFavorite: !updated.isFavorite));
              },
            ),
            IconButton(
              tooltip: s.t('reminder'),
              icon: Icon(
                  _hasActiveReminder ? Icons.notifications_active : Icons.notifications_none,
                  color: _hasActiveReminder ? Colors.amber : null),
              onPressed: _onReminderPressed,
            ),
            IconButton(
              tooltip: s.t('tags'),
              icon: const Icon(Icons.label_outline),
              onPressed: () => _editTags(s),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () async {
                await _ensureSaved();
                if (mounted) {
                  await showNoteActions(context, _note,
                      onDetails: () => _showDetails(s),
                      onFind: _canFindInNote ? () => _openFind() : null,
                      onStats: (_note.type == NoteType.text ||
                              _note.type == NoteType.checklist)
                          ? () => _showStats(s)
                          : null);
                }
                // أعد التحميل لتحديث الحالة (لون/تثبيت/قفل).
                final fresh = await context
                    .read<NotesProvider>()
                    .notes
                    .getNote(_note.id!);
                if (!mounted) return;
                // حُذفت (نُقلت للمهملات) ⇒ أغلق المحرّر دون إعادة حفظها.
                if (fresh == null || fresh.isDeleted) {
                  _deleted = true;
                  Navigator.pop(context);
                  return;
                }
                setState(() => _note = fresh);
              },
            ),
          ],
        ),
        body: SafeArea(
          child: DefaultTextStyle.merge(
            style: TextStyle(color: _fgColor),
            child: Column(
            children: [
              if (_findVisible) _buildFindBar(s),
              Expanded(
                child: _note.type == NoteType.text
                    ? _textLayout(s, onBg, settings)
                    : ListView(
                        // حشوة سفلية بقدر لوحة المفاتيح كي تبقى العناصر السفلية
                        // (ومنها مربعات الاختيار) قابلة للتمرير فوقها والضغط عليها.
                        padding: EdgeInsets.fromLTRB(16, 8, 16,
                            24 + MediaQuery.of(context).viewInsets.bottom),
                        children: [
                          PaperBackground(
                            style: _note.bgStyle,
                            lineColor: onBg,
                            gap: noteLineGap(settings,
                                lineHeight: _note.ruleLineHeight),
                            thickness:
                                _note.ruleThickness ?? settings.ruleThickness,
                            opacity:
                                _note.ruleOpacity ?? settings.ruleOpacity,
                            onLine: _note.ruleOnLine ?? settings.ruleOnLine,
                            fontSize: settings.noteFontSize,
                            topPadding: 0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ..._typeBody(s),
                                _attachmentsSection(s, onBg),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              // شريط أدوات التنسيق فوق لوحة المفاتيح مباشرة (يرتفع معها).
              // عند إخفاء الكيبورد نرفعه قليلًا عن الحافة كي لا يقع سحبه الأفقي
              // في منطقة إيماءات النظام السفلية (تبديل التطبيق/الرجوع).
              if (_note.type == NoteType.text && _richCtrl != null)
                Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom > 0
                          ? MediaQuery.of(context).viewInsets.bottom
                          : 6),
                  child: RichTextToolbar(
                    controller: _richCtrl!,
                    onExportPdf: _exportPdf,
                    onExportWord: _exportWord,
                  ),
                ),
            ],
          ),
          ),
        ),
    );

    final decorated = grad != null
        ? Container(
            decoration: BoxDecoration(gradient: grad.toGradient()),
            child: scaffold,
          )
        : scaffold;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onWillPop();
        if (mounted) Navigator.pop(context);
      },
      child: decorated,
    );
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}/${two(d.month)}/${two(d.day)}  ${two(d.hour)}:${two(d.minute)}';
  }

  // يُستخدم داخل شيت «التفاصيل» (خارج build) ⇒ نقرأ القائمة بـ read، ونحدّث
  // القيمة المعروضة محليًّا عبر StatefulBuilder.
  Widget _categorySelector(S s) {
    final provider = context.read<NotesProvider>();
    return StatefulBuilder(
      builder: (context, setSel) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: DropdownButton<int?>(
          value: _note.categoryId,
          isExpanded: true,
          isDense: true,
          hint: Text(s.t('no_category')),
          underline: const SizedBox.shrink(),
          items: [
            DropdownMenuItem(value: null, child: Text(s.t('no_category'))),
            ...provider.categories.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    CircleAvatar(radius: 6, backgroundColor: Color(c.color)),
                    const SizedBox(width: 8),
                    Text(c.name),
                  ]),
                )),
          ],
          onChanged: (v) async {
            setState(
                () => _note = _note.copyWith(categoryId: v, clearCategory: v == null));
            setSel(() {});
            _dirty = true;
            await _save(force: true);
          },
        ),
      ),
    );
  }

  /// «تفاصيل» الملاحظة: تحرير العنوان والتصنيف، عرض التواريخ، وزر الحذف.
  Future<void> _showDetails(S s) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 4,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تفاصيل الملاحظة',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (ctx, setTitle) => TextField(
                controller: _titleCtrl,
                textInputAction: TextInputAction.done,
                textDirection: lineDirection(_titleCtrl.text),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: s.t('title_hint'),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) {
                  _dirty = true;
                  setTitle(() {}); // تحديث اتجاه العنوان فورًا
                  if (mounted) setState(() {});
                },
              ),
            ),
            const SizedBox(height: 12),
            _categorySelector(s),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule,
                    size: 18, color: Theme.of(context).hintColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'أُنشئت: ${_formatDate(_note.createdAt)}\n'
                    'عُدّلت: ${_formatDate(_note.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () async {
                  Navigator.pop(sheetCtx);
                  await _deleteNote();
                },
                icon: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                label: Text(s.t('delete'),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ينقل الملاحظة إلى المهملات ويُغلق المحرّر دون إعادة حفظها (بعد تأكيد).
  Future<void> _deleteNote() async {
    if (!await confirmDeleteNote(context)) return;
    await _ensureSaved();
    if (_note.id != null) {
      await context.read<NotesProvider>().moveToTrash(_note);
    }
    _deleted = true;
    if (mounted) Navigator.pop(context);
  }

  /// تخطيط ملاحظة النص: العنوان ثابت بالأعلى، والمحرّر يملأ الباقي ويمرّر
  /// داخليًا (viewport) — أداء سلس حتى مع المستندات الطويلة جدًّا.
  Widget _textLayout(S s, Color onBg, SettingsProvider settings) {
    // العنوان والتاريخ مخفيّان من الصفحة (يظهران في «تفاصيل» بقائمة الثلاث نقاط)
    // لتوفير أقصى مساحة للكتابة.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _richCtrl == null
              ? const SizedBox.shrink()
              // يُعاد بناء التسطير فقط (لا المحرّر) عند تغيّر المحتوى/الحجم.
              // نستمع لـ docRevision (تغيّر المستند) لا لكامل وحدة التحكّم، كي لا
              // يُعاد حساب التسطير في كل تحريك مؤشّر/سحب تحديد ⇒ تحديد ناعم.
              : ValueListenableBuilder<int>(
                  valueListenable: _richCtrl!.docRevision,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RichTextEditorBody(
                        controller: _richCtrl!,
                        expand: true,
                        lineHeight: _note.ruleLineHeight),
                  ),
                  builder: (context, _, child) {
                    final lh = _note.ruleLineHeight ?? settings.noteLineHeight;
                    // حجم موحّد ⇒ تسطير منضبط معه؛ أحجام مختلطة (null) ⇒ نُلغي
                    // التسطير (نمط سادة) لأنه لا ينضبط مع أسطر متفاوتة الارتفاع.
                    final rulingSize =
                        noteRulingFontSize(_richCtrl!.quill, settings.noteFontSize);
                    final baseFont = rulingSize ?? settings.noteFontSize;
                    return PaperBackground(
                      style: rulingSize == null ? 0 : _note.bgStyle,
                      lineColor: onBg,
                      gap: baseFont * lh,
                      thickness: _note.ruleThickness ?? settings.ruleThickness,
                      opacity: _note.ruleOpacity ?? settings.ruleOpacity,
                      onLine: _note.ruleOnLine ?? settings.ruleOnLine,
                      fontSize: baseFont,
                      topPadding: 8,
                      // تتحرّك الأسطر مع تمرير الكتابة وتبقى محاذية لها.
                      scrollController: _richCtrl?.scroll,
                      child: child!,
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// النصّ الخام للإحصاء (من المحرّر الحيّ إن توفّر، وإلا من المحتوى المحفوظ).
  String _statsText() {
    if (_note.type == NoteType.checklist) {
      return _itemCtrls.map((c) => c.text).join('\n');
    }
    if (_richCtrl != null) {
      return _richCtrl!.quill.document.toPlainText();
    }
    return richToPlainText(_note.content);
  }

  /// ورقة إحصائيات الملاحظة: كلمات/أحرف/أسطر + زمن قراءة تقريبيّ.
  void _showStats(S s) {
    final text = _statsText();
    final words =
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final chars = text.replaceAll('\n', '').length;
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).length;
    final minutes = (words / 200).ceil();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        Widget row(IconData i, String label, String v) => ListTile(
              leading: Icon(i, color: Theme.of(ctx).colorScheme.primary),
              title: Text(label),
              trailing: Text(v,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(children: [
                  Icon(Icons.bar_chart,
                      color: Theme.of(ctx).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(s.t('stats'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17)),
                ]),
              ),
              row(Icons.text_fields, s.t('words'), '$words'),
              row(Icons.abc, s.t('characters'), '$chars'),
              row(Icons.notes, s.t('lines'), '$lines'),
              row(Icons.schedule, s.t('reading_time'),
                  '$minutes ${s.t('minute')}'),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  /// يفتح ملاحظة كلمة مرور مرتبطة (علاقة) بعد فتح القفل.
  Future<void> _openRelation(int id) async {
    await _ensureSaved();
    if (!mounted) return;
    final ok = await ensureUnlocked(context);
    if (!ok || !mounted) return;
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: id)));
  }

  List<Widget> _typeBody(S s) {
    switch (_note.type) {
      case NoteType.checklist:
        return _checklistBody(s);
      case NoteType.image:
        return _imageBody(s);
      case NoteType.audio:
        return _audioBody(s);
      case NoteType.pdf:
        return _pdfBody(s);
      case NoteType.drawing:
        return _drawingBody(s);
      case NoteType.password:
        return [
          PasswordForm(
            initial: _passwordEntry,
            noteId: _note.id,
            fetchRefs: () =>
                context.read<NotesProvider>().notes.passwordRefs(),
            onOpenRelation: _openRelation,
            onChanged: (entry) {
              _passwordEntry = entry;
              _onChanged();
            },
          ),
        ];
      case NoteType.treatment:
        return [
          TreatmentForm(
            initial: _treatmentEntry,
            onChanged: (entry) {
              _treatmentEntry = entry;
              _onChanged();
            },
          ),
        ];
      case NoteType.text:
        return [
          if (_richCtrl != null) RichTextEditorBody(controller: _richCtrl!),
        ];
    }
  }

  Widget _contentField(S s) {
    return TextField(
      controller: _contentCtrl,
      focusNode: _contentFocus,
      maxLines: null,
      minLines: 8,
      textDirection: lineDirection(_contentCtrl.text),
      style: TextStyle(fontSize: 16, height: 1.5, color: _fgColor),
      decoration: InputDecoration(
        hintText: s.t('content_hint'),
        border: InputBorder.none,
        filled: false,
      ),
    );
  }

  /// شريط تقدّم قائمة المهام: نسبة المنجَز + «منجَز/الإجمالي» (يتلوّن أخضرَ عند
  /// اكتمال كل المهام).
  Widget _checklistProgress(S s, int done, int total) {
    final ratio = total == 0 ? 0.0 : done / total;
    final complete = done == total;
    final scheme = Theme.of(context).colorScheme;
    final color = complete ? Colors.green : scheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(complete ? Icons.check_circle : Icons.checklist,
                  size: 18, color: color),
              const SizedBox(width: 6),
              Text('${s.t('checklist_progress')}: $done/$total',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontSize: 13)),
              const Spacer(),
              Text('${(ratio * 100).round()}%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: scheme.surfaceContainerHighest,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _checklistBody(S s) {
    // نمط الكتابة من إعدادات الصفحة الافتراضية (الخط/الحجم/التباعد/اللون).
    final settings = context.read<SettingsProvider>();
    final base = TextStyle(
      fontFamily: settings.noteFontFamily,
      fontSize: settings.noteFontSize,
      height: settings.noteLineHeight,
      color: _fgColor,
    );
    final total = _checklist.where((c) => c.isTask).length;
    final done = _checklist.where((c) => c.isTask && c.isDone).length;
    return [
      if (total > 0) _checklistProgress(s, done, total),
      for (var i = 0; i < _checklist.length; i++)
        ChecklistTile(
          key: ValueKey('item_${_itemCtrls[i].hashCode}'),
          controller: _itemCtrls[i],
          focusNode: _itemFocus[i],
          baseStyle: base,
          isDone: _checklist[i].isDone,
          isTask: _checklist[i].isTask,
          onToggle: (v) {
            setState(() => _checklist[i] = _checklist[i].copyWith(isDone: v));
            _onChanged();
          },
          onToggleType: () {
            setState(() => _checklist[i] = _checklist[i]
                .copyWith(isTask: !_checklist[i].isTask, isDone: false));
            _onChanged();
          },
          onTextChanged: _onChanged,
          onSubmit: (rest) => _addItemAfter(i, text: rest),
          onDelete: () {
            setState(() {
              _checklist.removeAt(i);
              _itemCtrls.removeAt(i).dispose();
              _itemFocus.removeAt(i).dispose();
            });
            _onChanged();
          },
        ),
      TextButton.icon(
        onPressed: () {
          setState(() {
            _checklist.add(ChecklistItem(noteId: _note.id ?? 0, text: ''));
            _itemCtrls.add(TextEditingController());
            _itemFocus.add(FocusNode());
          });
        },
        icon: const Icon(Icons.add),
        label: Text(s.t('add_item')),
      ),
    ];
  }

  List<Widget> _imageBody(S s) {
    return [
      if (_note.imagePath != null && File(_note.imagePath!).existsSync())
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          // نفكّ الصورة بدقّة العرض (لا الكاملة) لتفادي التهام الذاكرة.
          child: Image.file(File(_note.imagePath!),
              fit: BoxFit.cover, cacheWidth: 1280),
        )
      else
        _attachButton(s.t('note_image'), Icons.add_photo_alternate, _attachImage),
      const SizedBox(height: 8),
      if (_note.imagePath != null)
        Row(
          children: [
            TextButton.icon(
              onPressed: _attachImage,
              icon: const Icon(Icons.edit),
              label: const Text('تغيير'),
            ),
            TextButton.icon(
              onPressed: () => _removeMedia(image: true, label: 'الصورة'),
              icon: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              label: Text('حذف الصورة',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        ),
      _contentField(s),
    ];
  }

  List<Widget> _audioBody(S s) {
    return [
      AudioNoteWidget(
        existingPath: _note.audioPath,
        onRecorded: (path) async {
          setState(() => _note = _note.copyWith(audioPath: path));
          _dirty = true;
          await _ensureSaved();
          await _save(force: true);
        },
      ),
      if (_note.audioPath != null)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => _removeMedia(audio: true, label: 'التسجيل'),
            icon: Icon(Icons.delete_outline,
                color: Theme.of(context).colorScheme.error),
            label: Text('حذف التسجيل',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ),
      const SizedBox(height: 12),
      _contentField(s),
    ];
  }

  List<Widget> _pdfBody(S s) {
    return [
      if (_note.pdfPath != null)
        ListTile(
          leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
          title: Text(_note.pdfPath!.split('/').last,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () => EditorAttachments.openFile(_note.pdfPath!),
              ),
              IconButton(
                tooltip: 'حذف',
                icon: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                onPressed: () => _removeMedia(pdf: true, label: 'ملفّ PDF'),
              ),
            ],
          ),
        )
      else
        _attachButton(s.t('note_pdf'), Icons.attach_file, _attachPdf),
      const SizedBox(height: 8),
      _contentField(s),
    ];
  }

  List<Widget> _drawingBody(S s) {
    return [
      if (_note.drawingPath != null && File(_note.drawingPath!).existsSync())
        GestureDetector(
          onTap: _editDrawing,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              color: Colors.white,
              child: Image.file(File(_note.drawingPath!),
                  fit: BoxFit.contain, cacheWidth: 1280),
            ),
          ),
        )
      else
        _attachButton(s.t('drawing'), Icons.brush, _editDrawing),
      const SizedBox(height: 8),
      if (_note.drawingPath != null)
        Row(
          children: [
            TextButton.icon(
              onPressed: _editDrawing,
              icon: const Icon(Icons.edit),
              label: const Text('تعديل'),
            ),
            TextButton.icon(
              onPressed: () => _removeMedia(drawing: true, label: 'الرسم'),
              icon: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              label: Text('حذف الرسم',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        )
      else
        TextButton.icon(
          onPressed: _editDrawing,
          icon: const Icon(Icons.edit),
          label: Text(s.t('drawing')),
        ),
      _contentField(s),
    ];
  }

  Widget _attachButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Theme.of(context).dividerColor, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  // ============ مرفقات متعددة (صور + PDF) لأي ملاحظة ============

  /// قسم المرفقات: شبكة معاينات + زرّ إضافة مفتوح (صور متعددة / ملفات PDF).
  Widget _attachmentsSection(S s, Color onBg) {
    final items = _note.attachments;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file, size: 18, color: onBg.withOpacity(0.75)),
              const SizedBox(width: 6),
              Text(
                items.isEmpty ? 'المرفقات' : 'المرفقات (${items.length})',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: onBg.withOpacity(0.9)),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addAttachments,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('إضافة'),
              ),
            ],
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Text(
                'أضف صورًا أو ملفات PDF (يمكن اختيار عدّة ملفات دفعة واحدة).',
                style: TextStyle(fontSize: 12, color: onBg.withOpacity(0.6)),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) => _attachmentTile(items[i], i),
            ),
        ],
      ),
    );
  }

  Widget _attachmentTile(NoteAttachment a, int index) {
    final exists = a.path.isNotEmpty && File(a.path).existsSync();
    return Stack(
      children: [
        Positioned.fill(
          child: InkWell(
            onTap: () => _openAttachment(a),
            borderRadius: BorderRadius.circular(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: a.isImage && exists
                  ? Image.file(File(a.path),
                      fit: BoxFit.cover,
                      cacheWidth: 360,
                      filterQuality: FilterQuality.low)
                  : Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              a.isPdf
                                  ? Icons.picture_as_pdf
                                  : Icons.broken_image_outlined,
                              size: 34,
                              color: a.isPdf ? Colors.red : Colors.grey),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              a.isPdf ? (a.name ?? 'PDF') : 'ملف مفقود',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        // زرّ خيارات (⋮) بدل زرّ حذف مكشوف — لتفادي الحذف بالخطأ.
        Positioned(
          top: 2,
          left: 2,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _attachmentOptions(a, index),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.more_vert, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// يفتح المرفق «داخل الملاحظة»: الصور في عارض ملء الشاشة (تكبير/تنقّل)،
  /// وملفات PDF بعارض النظام.
  Future<void> _openAttachment(NoteAttachment a) async {
    if (a.path.isEmpty || !File(a.path).existsSync()) return;
    if (a.isImage) {
      final images = _note.attachments.where((e) => e.isImage).toList();
      final idx = images.indexWhere((e) => e.path == a.path);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AttachmentViewer(
              images: images, initialIndex: idx < 0 ? 0 : idx),
        ),
      );
    } else {
      await EditorAttachments.openFile(a.path);
    }
  }

  /// إرسال/مشاركة مرفق واحد (واتساب، مدير الملفات، …).
  Future<void> _shareAttachment(NoteAttachment a) async {
    if (a.path.isEmpty || !File(a.path).existsSync()) return;
    final mime = a.isPdf ? 'application/pdf' : 'image/jpeg';
    await SharePlus.instance
        .share(ShareParams(files: [XFile(a.path, mimeType: mime)]));
  }

  /// ورقة خيارات المرفق: فتح / إرسال / حذف (الحذف بتأكيد — أكثر أمانًا).
  Future<void> _attachmentOptions(NoteAttachment a, int index) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.open_in_full),
            title: const Text('فتح'),
            onTap: () => Navigator.pop(ctx, 'open'),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('إرسال (واتساب / مدير الملفات …)'),
            onTap: () => Navigator.pop(ctx, 'share'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('حذف', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pop(ctx, 'delete'),
          ),
        ]),
      ),
    );
    if (choice == 'open') {
      await _openAttachment(a);
    } else if (choice == 'share') {
      await _shareAttachment(a);
    } else if (choice == 'delete') {
      await _removeAttachment(index);
    }
  }

  /// يفتح ورقة اختيار: صور من المعرض / كاميرا / ملفات PDF.
  Future<void> _addAttachments() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('صور من المعرض (عدّة صور)'),
            onTap: () => Navigator.pop(ctx, 'images'),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('التقاط صورة بالكاميرا'),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('ملفات PDF (عدّة ملفات)'),
            onTap: () => Navigator.pop(ctx, 'pdf'),
          ),
        ]),
      ),
    );
    if (choice == null) return;

    final added = <NoteAttachment>[];
    if (choice == 'images') {
      for (final p in await EditorAttachments.pickImages()) {
        added.add(NoteAttachment(path: p, kind: 'image'));
      }
    } else if (choice == 'camera') {
      final p = await EditorAttachments.captureImage();
      if (p != null) added.add(NoteAttachment(path: p, kind: 'image'));
    } else if (choice == 'pdf') {
      for (final f in await EditorAttachments.pickPdfs()) {
        added.add(NoteAttachment(path: f.path, kind: 'pdf', name: f.name));
      }
    }
    if (added.isEmpty) return;
    setState(() {
      _note = _note.copyWith(attachments: [..._note.attachments, ...added]);
    });
    _dirty = true;
    await _ensureSaved();
    await _save(force: true);
  }

  Future<void> _removeAttachment(int index) async {
    if (index < 0 || index >= _note.attachments.length) return;
    final a = _note.attachments[index];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('حذف المرفق؟'),
        content: const Text('سيُحذف هذا المرفق نهائيًّا من الملاحظة.'),
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
    if (ok != true) return;
    final next = [..._note.attachments]..removeAt(index);
    setState(() => _note = _note.copyWith(attachments: next));
    _dirty = true;
    await _save(force: true);
    // نظّف الملف من القرص (لا يمسّ غيره).
    await FileService.instance.deleteIfExists(a.path);
  }

  /// تحرير وسوم الملاحظة في ورقة سفلية تُفتح عند الطلب فقط (لا تشغل حيّزًا دائمًا).
  Future<void> _editTags(S s) async {
    await _ensureSaved();
    if (!mounted) return;
    final ctrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.t('tags'),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (_note.tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in _note.tags)
                      Chip(
                        label: Text('#$t'),
                        onDeleted: () async {
                          final updated = List<String>.from(_note.tags)
                            ..remove(t);
                          _note = _note.copyWith(tags: updated);
                          await _save(force: true);
                          setSheet(() {});
                          if (mounted) setState(() {});
                        },
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: s.t('add_tag'),
                  prefixIcon: const Icon(Icons.tag),
                ),
                onSubmitted: (value) async {
                  final v = value.trim();
                  if (v.isEmpty) return;
                  final updated = List<String>.from(_note.tags)..add(v);
                  _note = _note.copyWith(tags: updated);
                  ctrl.clear();
                  await _save(force: true);
                  setSheet(() {});
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// عنصر سطر في قائمة المهام: مربع اختيار يعمل + كتابة بمحاذاة تلقائية لكل سطر.
///
/// عنصر مستقلّ بحالته الخاصة كي يتحدّث اتجاهه دون إعادة بناء القائمة كلها (ما
/// كان يُفسد لمس بعض المربعات). عربي ⇒ المربع يمين والكتابة يمين، إنجليزي ⇒ العكس.
class ChecklistTile extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextStyle baseStyle; // نمط الكتابة من إعدادات الصفحة الافتراضية
  final bool isDone;
  final bool isTask; // مهمة (بمربع) أو نصّ عادي (بلا مربع)
  final ValueChanged<bool> onToggle;
  final VoidCallback onToggleType; // تحويل مهمة⇄نص
  final VoidCallback onTextChanged;
  // Enter ⇒ سطر/مهمة جديدة. الوسيط = النصّ المنقول لما بعد المؤشّر (عند التقسيم).
  final ValueChanged<String> onSubmit;
  final VoidCallback onDelete;

  const ChecklistTile({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.baseStyle,
    required this.isDone,
    required this.isTask,
    required this.onToggle,
    required this.onToggleType,
    required this.onTextChanged,
    required this.onSubmit,
    required this.onDelete,
  });

  /// اتجاه النص حسب أول حرف قويّ (الدالة المشتركة الموحّدة في كل التطبيق).
  static TextDirection dirOf(String s) => lineDirection(s);

  @override
  State<ChecklistTile> createState() => _ChecklistTileState();
}

class _ChecklistTileState extends State<ChecklistTile> {
  late TextDirection _dir;

  @override
  void initState() {
    super.initState();
    _dir = ChecklistTile.dirOf(widget.controller.text);
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(covariant ChecklistTile old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
      _dir = ChecklistTile.dirOf(widget.controller.text);
    }
  }

  void _onText() {
    final text = widget.controller.text;
    // كشف موثوق لـ Enter على **كل** لوحات المفاتيح: في حقل متعدّد الأسطر يُدرج
    // Enter محرف سطر جديد دائمًا (بخلاف onSubmitted الذي قد لا يُطلَق على حقل
    // فارغ في بعض اللوحات — وهو سبب «لا ينزل سطر جديد إلا بعد الكتابة»).
    if (text.contains('\n')) {
      final idx = text.indexOf('\n');
      final before = text.substring(0, idx);
      final after = text.substring(idx + 1);
      // أبقِ ما قبل Enter في السطر الحالي (دفعة واحدة لتفادي وميض سطرين).
      widget.controller.value = TextEditingValue(
        text: before,
        selection: TextSelection.collapsed(offset: before.length),
      );
      final d = ChecklistTile.dirOf(before);
      if (d != _dir && mounted) setState(() => _dir = d);
      widget.onSubmit(after); // أنشئ سطرًا جديدًا (مع النص المنقول إن وُجد).
      return;
    }
    final d = ChecklistTile.dirOf(text);
    if (d != _dir && mounted) setState(() => _dir = d);
    widget.onTextChanged();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: _dir,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // مهمة: مربع اختيار (لمس = تعليم، لمس مطوّل = تحويل لنصّ).
          // نصّ عادي: دائرة باهتة (لمس = تحويل لمهمة).
          if (widget.isTask)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onToggle(!widget.isDone),
              onLongPress: widget.onToggleType,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Icon(
                  widget.isDone
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 22,
                  color: widget.isDone ? scheme.primary : scheme.outline,
                ),
              ),
            )
          else
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onToggleType,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Icon(Icons.radio_button_unchecked,
                    size: 16, color: scheme.outline.withValues(alpha: 0.5)),
              ),
            ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              textDirection: _dir,
              // حقل متعدّد الأسطر كي يُدرج Enter محرف سطر نلتقطه في [_onText]
              // ونحوّله إلى عنصر جديد — يعمل حتى على السطر الأول الفارغ.
              minLines: 1,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: widget.baseStyle.copyWith(
                decoration: (widget.isTask && widget.isDone)
                    ? TextDecoration.lineThrough
                    : null,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDelete,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(Icons.close, size: 18, color: scheme.outline),
            ),
          ),
        ],
      ),
    );
  }
}
