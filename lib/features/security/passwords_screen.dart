import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../data/models/enums.dart';
import '../../data/models/note.dart';
import '../../services/secure_screen.dart';
import '../../widgets/note_actions.dart';
import '../../widgets/note_card.dart';
import '../../widgets/ui_kit.dart';
import '../editor/note_editor_screen.dart';
import '../home/notes_provider.dart';

/// قسم النظام المخصّص لكلمات المرور — يعرض ملاحظات نوع «كلمة المرور» فقط.
/// يُدخَل إليه بعد فتح القفل، ويُفعّل منع التصوير (FLAG_SECURE) طوال وجوده.
class PasswordsScreen extends StatefulWidget {
  const PasswordsScreen({super.key});

  @override
  State<PasswordsScreen> createState() => _PasswordsScreenState();
}

class _PasswordsScreenState extends State<PasswordsScreen> {
  List<Note> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    SecureScreen.enable();
    _load();
  }

  @override
  void dispose() {
    SecureScreen.disable();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final items = await context.read<NotesProvider>().getPasswordNotes();
    if (mounted) setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _add() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              const NoteEditorScreen(initialType: NoteType.password)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<NotesProvider>();

    return Scaffold(
      appBar: gradientAppBar(context, 'كلمات المرور',
          leading: const Icon(Icons.vpn_key)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('كلمة مرور'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const EmptyState(
                  icon: Icons.vpn_key_outlined,
                  title: 'لا كلمات مرور بعد',
                  subtitle: 'أضِف أوّل كلمة مرور بزرّ +')
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                  children: _items
                      .map((n) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: NoteCard(
                              note: n,
                              revealLocked: true,
                              category: provider.categoryById(n.categoryId),
                              onTap: () async {
                                // داخل القسم المستخدم موثّق؛ نفتح مباشرة.
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            NoteEditorScreen(noteId: n.id)));
                                await _load();
                              },
                              onLongPress: () async {
                                await showNoteActions(context, n);
                                await _load();
                              },
                            ),
                          ))
                      .toList(),
                ),
    );
  }
}
