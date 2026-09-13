import 'package:flutter/material.dart';

import '../../services/movement_break_service.dart';

/// إعداد تنبيه «لا تجلس طويلًا»: تفعيل، فترات (حتى ٣) بوقت بداية ومدّة حركة،
/// ورمز تخطٍّ معقّد.
class MovementBreakSettingsScreen extends StatefulWidget {
  const MovementBreakSettingsScreen({super.key});

  @override
  State<MovementBreakSettingsScreen> createState() =>
      _MovementBreakSettingsScreenState();
}

class _MovementBreakSettingsScreenState
    extends State<MovementBreakSettingsScreen> {
  bool _enabled = false;
  late List<BreakPeriod> _periods;
  final _codeCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = MovementBreakService.instance;
    await svc.load();
    _enabled = svc.enabled;
    _periods = svc.periods
        .map((p) => BreakPeriod(
            startMinutes: p.startMinutes,
            moveMinutes: p.moveMinutes,
            enabled: p.enabled))
        .toList();
    _codeCtrl.text = svc.bypassCode;
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  String _fmtMin(int minutes) {
    final h = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Future<void> _pickStart(int i) async {
    final cur = _periods[i].startMinutes;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (cur ~/ 60) % 24, minute: cur % 60),
    );
    if (t != null) {
      setState(() => _periods[i].startMinutes = t.hour * 60 + t.minute);
    }
  }

  Future<void> _save() async {
    await MovementBreakService.instance.save(
      enabled: _enabled,
      periods: _periods,
      bypassCode: _codeCtrl.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('حُفظ إعداد التنبيه')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('لا تجلس طويلًا')),
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
                  child: const Row(
                    children: [
                      Icon(Icons.self_improvement),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'يغطّي الشاشة بهدوء (بلا صوت) خلال فترات الحركة، ولا '
                          'يُفتح إلا بانتهاء المدّة أو إدخال الرمز. يعمل أثناء '
                          'استخدام التطبيق.',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                  title: const Text('تفعيل التنبيه',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                const SizedBox(height: 4),
                Text('الفترات (حتى ٣)',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: scheme.primary)),
                const SizedBox(height: 8),
                for (var i = 0; i < _periods.length; i++) _periodCard(i, scheme),
                if (_periods.length < 3)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _periods.add(
                          BreakPeriod(startMinutes: 13 * 60, moveMinutes: 5))),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة فترة'),
                    ),
                  ),
                const Divider(),
                const SizedBox(height: 8),
                Text('رمز التخطّي (للضرورة)',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: scheme.primary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'رمز معقّد (أرقام)',
                    hintText: 'مثال: 738214',
                    helperText:
                        'يُطلب لفتح الشاشة قبل انتهاء المدّة. اتركه فارغًا '
                        'لمنع التخطّي نهائيًّا.',
                    helperMaxLines: 2,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.password),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ'),
                ),
              ],
            ),
    );
  }

  Widget _periodCard(int i, ColorScheme scheme) {
    final p = _periods[i];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                Text('فترة ${i + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Switch(
                  value: p.enabled,
                  onChanged: (v) => setState(() => p.enabled = v),
                ),
                IconButton(
                  tooltip: 'حذف',
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                  onPressed: () => setState(() => _periods.removeAt(i)),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickStart(i),
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text('تبدأ ${_fmtMin(p.startMinutes)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text('تنتهي ${_fmtMin(p.endMinutes)}',
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('مدّة الحركة:'),
                Expanded(
                  child: Slider(
                    value: p.moveMinutes.toDouble().clamp(1, 30),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    label: '${p.moveMinutes} د',
                    onChanged: (v) =>
                        setState(() => p.moveMinutes = v.round()),
                  ),
                ),
                Text('${p.moveMinutes} دقيقة',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
