import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/text/arabic_search.dart';
import '../../data/models/enums.dart';
import '../../data/models/note.dart';
import '../../data/models/treatment_entry.dart';
import '../../widgets/note_actions.dart';
import '../../widgets/note_card.dart';
import '../../widgets/ui_kit.dart';
import '../editor/note_editor_screen.dart';
import '../home/notes_provider.dart';

enum _TSort { section, brand, newest, oldest }

/// قسم النظام المخصّص للعلاج/الدواء — يعرض ملاحظات نوع «علاج» فقط، مع بحث ذكيّ
/// وترتيب (افتراضيًّا حسب القسم مع رؤوس مجموعات).
class TreatmentsScreen extends StatefulWidget {
  const TreatmentsScreen({super.key});

  @override
  State<TreatmentsScreen> createState() => _TreatmentsScreenState();
}

class _TreatmentsScreenState extends State<TreatmentsScreen> {
  List<Note> _items = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _query = '';
  _TSort _sort = _TSort.section;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final items = await context.read<NotesProvider>().getTreatmentNotes();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _add() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              const NoteEditorScreen(initialType: NoteType.treatment)),
    );
    await _load();
  }

  List<Note> get _visible {
    final needle = normalizeArabic(_query);
    var list = _items;
    if (needle.isNotEmpty) {
      list = list
          .where((n) => normalizeArabic(
                  TreatmentEntry.searchableFromJson(n.content))
              .contains(needle))
          .toList();
    } else {
      list = List<Note>.from(list);
    }
    int bySection(Note a, Note b) {
      final sa = TreatmentEntry.fromStoredJson(a.content).sectionLabel;
      final sb = TreatmentEntry.fromStoredJson(b.content).sectionLabel;
      final c = normalizeArabic(sa).compareTo(normalizeArabic(sb));
      if (c != 0) return c;
      return normalizeArabic(TreatmentEntry.titleFromJson(a.content))
          .compareTo(normalizeArabic(TreatmentEntry.titleFromJson(b.content)));
    }

    switch (_sort) {
      case _TSort.section:
        list.sort(bySection);
      case _TSort.brand:
        list.sort((a, b) => normalizeArabic(
                TreatmentEntry.titleFromJson(a.content))
            .compareTo(
                normalizeArabic(TreatmentEntry.titleFromJson(b.content))));
      case _TSort.newest:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case _TSort.oldest:
        list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    }
    return list;
  }

  String _sortLabel(_TSort s) => switch (s) {
        _TSort.section => 'القسم',
        _TSort.brand => 'الاسم التجاري',
        _TSort.newest => 'الأحدث',
        _TSort.oldest => 'الأقدم',
      };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final scheme = Theme.of(context).colorScheme;
    final visible = _visible;
    final grouped = _sort == _TSort.section;

    return Scaffold(
      appBar: gradientAppBar(
        context,
        'العلاج',
        actions: [
          PopupMenuButton<_TSort>(
            tooltip: 'الترتيب',
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => [
              for (final s in _TSort.values)
                PopupMenuItem<_TSort>(
                  value: s,
                  child: Row(children: [
                    Icon(
                        _sort == s
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 18),
                    const SizedBox(width: 10),
                    Text(_sortLabel(s)),
                  ]),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('علاج'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'بحث في العلاجات…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                  child: Row(children: [
                    Text('${visible.length} عنصر',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant)),
                    const Spacer(),
                    Icon(Icons.sort, size: 14, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(_sortLabel(_sort),
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant)),
                  ]),
                ),
                Expanded(
                  child: _items.isEmpty
                      ? const EmptyState(
                          icon: Icons.medication_outlined,
                          title: 'لا علاجات بعد',
                          subtitle: 'أضِف أوّل علاج بزرّ +')
                      : visible.isEmpty
                          ? const EmptyState(
                              icon: Icons.search_off,
                              title: 'لا نتائج',
                              subtitle: 'جرّب كلمة بحث أخرى')
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 4, 12, 88),
                              itemCount: visible.length,
                              itemBuilder: (context, i) {
                                final n = visible[i];
                                final showHeader = grouped &&
                                    (i == 0 ||
                                        TreatmentEntry.fromStoredJson(
                                                    visible[i - 1].content)
                                                .sectionLabel !=
                                            TreatmentEntry.fromStoredJson(
                                                    n.content)
                                                .sectionLabel);
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (showHeader)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            6, 10, 6, 2),
                                        child: Row(children: [
                                          Icon(Icons.folder_outlined,
                                              size: 16, color: scheme.primary),
                                          const SizedBox(width: 6),
                                          Text(
                                              TreatmentEntry.fromStoredJson(
                                                      n.content)
                                                  .sectionLabel,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: scheme.primary)),
                                        ]),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      child: NoteCard(
                                        note: n,
                                        category: provider
                                            .categoryById(n.categoryId),
                                        onTap: () async {
                                          await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      NoteEditorScreen(
                                                          noteId: n.id)));
                                          await _load();
                                        },
                                        onLongPress: () async {
                                          await showNoteActions(context, n);
                                          await _load();
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
