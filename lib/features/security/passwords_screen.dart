import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/text/arabic_search.dart';
import '../../data/models/enums.dart';
import '../../data/models/note.dart';
import '../../data/models/password_entry.dart';
import '../../services/secure_screen.dart';
import '../../widgets/note_actions.dart';
import '../../widgets/note_card.dart';
import '../../widgets/ui_kit.dart';
import '../editor/note_editor_screen.dart';
import '../home/notes_provider.dart';

/// ترتيب قائمة كلمات المرور.
enum _PwSort { titleAsc, newest, oldest, serial }

/// قسم النظام المخصّص لكلمات المرور — يعرض ملاحظات نوع «كلمة المرور» فقط، مع
/// بحث ذكيّ وترتيب. يُدخَل إليه بعد فتح القفل، ويُفعّل منع التصوير طوال وجوده.
class PasswordsScreen extends StatefulWidget {
  const PasswordsScreen({super.key});

  @override
  State<PasswordsScreen> createState() => _PasswordsScreenState();
}

class _PasswordsScreenState extends State<PasswordsScreen> {
  List<Note> _items = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _query = '';
  _PwSort _sort = _PwSort.titleAsc;

  @override
  void initState() {
    super.initState();
    SecureScreen.enable();
    _load();
  }

  @override
  void dispose() {
    SecureScreen.disable();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final items = await context.read<NotesProvider>().getPasswordNotes();
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
          builder: (_) => const NoteEditorScreen(initialType: NoteType.password)),
    );
    await _load();
  }

  /// القائمة بعد البحث الذكيّ والترتيب المختار.
  List<Note> get _visible {
    final needle = normalizeArabic(_query);
    var list = _items;
    if (needle.isNotEmpty) {
      list = list
          .where((n) => normalizeArabic(PasswordEntry.searchableFromJson(n.content))
              .contains(needle))
          .toList();
    } else {
      list = List<Note>.from(list);
    }
    int byTitle(Note a, Note b) => normalizeArabic(
            PasswordEntry.titleFromJson(a.content))
        .compareTo(normalizeArabic(PasswordEntry.titleFromJson(b.content)));
    switch (_sort) {
      case _PwSort.titleAsc:
        list.sort(byTitle);
      case _PwSort.newest:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case _PwSort.oldest:
        list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case _PwSort.serial:
        list.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    }
    return list;
  }

  String _sortLabel(_PwSort s) => switch (s) {
        _PwSort.titleAsc => 'العنوان (أ-ي)',
        _PwSort.newest => 'الأحدث',
        _PwSort.oldest => 'الأقدم',
        _PwSort.serial => 'الرقم التسلسلي',
      };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final scheme = Theme.of(context).colorScheme;
    final visible = _visible;

    return Scaffold(
      // لا نمرّر leading كي يظهر زرّ الرجوع التلقائي (خروج واضح من الصفحة).
      appBar: gradientAppBar(
        context,
        'كلمات المرور',
        actions: [
          PopupMenuButton<_PwSort>(
            tooltip: 'الترتيب',
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => [
              for (final s in _PwSort.values)
                PopupMenuItem<_PwSort>(
                  value: s,
                  child: Row(
                    children: [
                      Icon(
                          _sort == s
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 18),
                      const SizedBox(width: 10),
                      Text(_sortLabel(s)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('كلمة مرور'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // شريط البحث الذكيّ (يتجاهل الهمزة/التشكيل).
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'بحث في كلمات المرور…',
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
                // عدّاد + الترتيب الحالي.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                  child: Row(
                    children: [
                      Text('${visible.length} عنصر',
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant)),
                      const Spacer(),
                      Icon(Icons.sort, size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(_sortLabel(_sort),
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Expanded(
                  child: _items.isEmpty
                      ? const EmptyState(
                          icon: Icons.vpn_key_outlined,
                          title: 'لا كلمات مرور بعد',
                          subtitle: 'أضِف أوّل كلمة مرور بزرّ +')
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
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: NoteCard(
                                    note: n,
                                    revealLocked: true,
                                    category:
                                        provider.categoryById(n.categoryId),
                                    onTap: () async {
                                      await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => NoteEditorScreen(
                                                  noteId: n.id)));
                                      await _load();
                                    },
                                    onLongPress: () async {
                                      await showNoteActions(context, n);
                                      await _load();
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
