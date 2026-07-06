import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/treatment_entry.dart';

/// نموذج إدخال ملاحظة العلاج/الدواء — حقول منظّمة بالترتيب المطلوب، مع نسخ لكل
/// حقل (يظهر فقط حين يوجد نصّ). العنوان فوق كل حقل لوضوح مرتّب.
class TreatmentForm extends StatefulWidget {
  final TreatmentEntry initial;
  final ValueChanged<TreatmentEntry> onChanged;

  const TreatmentForm({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<TreatmentForm> createState() => _TreatmentFormState();
}

class _TreatmentFormState extends State<TreatmentForm> {
  late final Map<String, TextEditingController> _c;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    _c = {
      'section': TextEditingController(text: e.section),
      'brand': TextEditingController(text: e.brandName),
      'active': TextEditingController(text: e.activeIngredient),
      'concentration': TextEditingController(text: e.concentration),
      'dose': TextEditingController(text: e.dose),
      'usage': TextEditingController(text: e.usage),
      'duration': TextEditingController(text: e.duration),
      'cautions': TextEditingController(text: e.cautions),
      'side': TextEditingController(text: e.sideEffects),
      'notes': TextEditingController(text: e.notes),
    };
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged(TreatmentEntry(
      section: _c['section']!.text,
      brandName: _c['brand']!.text,
      activeIngredient: _c['active']!.text,
      concentration: _c['concentration']!.text,
      dose: _c['dose']!.text,
      usage: _c['usage']!.text,
      duration: _c['duration']!.text,
      cautions: _c['cautions']!.text,
      sideEffects: _c['side']!.text,
      notes: _c['notes']!.text,
    ));
  }

  Future<void> _copy(String v) async {
    if (v.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: v));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم النسخ'), duration: Duration(milliseconds: 900)));
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 6),
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Theme.of(context).colorScheme.primary)),
      );

  Widget _field(String label, String key, IconData icon, {int maxLines = 1}) {
    final ctrl = _c[key]!;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            onChanged: (_) => _emit(),
            decoration: InputDecoration(
              prefixIcon: Icon(icon),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: ctrl,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: 'نسخ',
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field('القسم', 'section', Icons.category_outlined),
        _field('اسم العلاج التجاري', 'brand', Icons.medication_outlined),
        _field('المادة الفعّالة', 'active', Icons.science_outlined),
        _field('التركيز', 'concentration', Icons.straighten),
        _field('الجرعة', 'dose', Icons.medication_liquid_outlined),
        _field('طريقة الاستخدام', 'usage', Icons.info_outline, maxLines: 2),
        _field('مدة الاستخدام', 'duration', Icons.schedule),
        _field('المحاذير', 'cautions', Icons.warning_amber_outlined,
            maxLines: 2),
        _field('الآثار الجانبية', 'side', Icons.healing_outlined, maxLines: 2),
        _field('ملاحظات', 'notes', Icons.notes, maxLines: 3),
      ],
    );
  }
}
