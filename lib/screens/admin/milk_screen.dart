import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Milk collection: pick a day and shift, then enter liters for every cow on
/// one screen and save in a single tap.
class MilkScreen extends StatefulWidget {
  const MilkScreen({super.key});

  @override
  State<MilkScreen> createState() => _MilkScreenState();
}

class _MilkScreenState extends State<MilkScreen> {
  DateTime _day = dateOnly(DateTime.now());
  Shift _shift = DateTime.now().hour < 14 ? Shift.morning : Shift.evening;
  final Map<String, TextEditingController> _liters = {};
  final Map<String, TextEditingController> _fat = {};
  String _loadedKey = '';

  @override
  void dispose() {
    for (final c in [..._liters.values, ..._fat.values]) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctl(Map<String, TextEditingController> m, String id) =>
      m.putIfAbsent(id, () => TextEditingController());

  /// Refill the inputs from saved records whenever day/shift changes.
  void _syncInputs(AppStore store, List<Cow> cows) {
    final saved = store.milkFor(day: _day);
    final key =
        '${_day.toIso8601String()}-${_shift.name}-${cows.length}-'
        '${saved.length}-${saved.fold(0.0, (s, m) => s + m.liters)}';
    if (key == _loadedKey) return;
    _loadedKey = key;
    for (final c in cows) {
      final r = store
          .milkFor(cowId: c.id, day: _day)
          .where((m) => m.shift == _shift)
          .firstOrNull;
      _ctl(_liters, c.id).text = r == null ? '' : qty(r.liters);
      _ctl(_fat, c.id).text = r?.fat == null ? '' : r!.fat.toString();
    }
  }

  void _saveAll(AppStore store, List<Cow> cows) {
    var saved = 0;
    for (final c in cows) {
      final l = double.tryParse(_ctl(_liters, c.id).text.trim());
      if (l == null || l <= 0) continue;
      store.milk.removeWhere(
        (m) => m.cowId == c.id && m.shift == _shift && sameDay(m.date, _day),
      );
      store.milk.add(
        MilkRecord(
          id: store.newId(),
          cowId: c.id,
          date: _day.add(Duration(hours: _shift == Shift.morning ? 6 : 18)),
          shift: _shift,
          liters: l,
          fat: double.tryParse(_ctl(_fat, c.id).text.trim()),
        ),
      );
      saved++;
    }
    store.save();
    FocusScope.of(context).unfocus();
    toast(
      context,
      saved == 0
          ? 'Enter liters for at least one cow'
          : 'Saved $saved entries ✓',
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cows =
        store.cows
            .where(
              (c) => c.status != CowStatus.calf && c.status != CowStatus.dry,
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    _syncInputs(store, cows);

    final isToday = sameDay(_day, DateTime.now());
    final morning = store.litersCollectedOn(_day, shift: Shift.morning);
    final evening = store.litersCollectedOn(_day, shift: Shift.evening);

    return Scaffold(
      appBar: AppBar(title: const Text('Milk collection')),
      body: cows.isEmpty
          ? const EmptyState(
              icon: Icons.water_drop_outlined,
              title: 'No milking cows',
              message: 'Add cows with status "Milking" in the Cattle tab',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                // Day picker
                Card(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setState(
                          () => _day = _day.subtract(const Duration(days: 1)),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await pickDate(
                              context,
                              _day,
                              last: DateTime.now(),
                            );
                            if (d != null) setState(() => _day = dateOnly(d));
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              children: [
                                Text(
                                  isToday ? 'Today' : fmtDay(_day),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  fmtDate(_day),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: isToday
                            ? null
                            : () => setState(
                                () => _day = _day.add(const Duration(days: 1)),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ShiftTotal(
                        '☀️ Morning',
                        morning,
                        _shift == Shift.morning,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ShiftTotal(
                        '🌙 Evening',
                        evening,
                        _shift == Shift.evening,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ShiftTotal('Σ Total', morning + evening, false),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SegmentedButton<Shift>(
                  segments: const [
                    ButtonSegment(
                      value: Shift.morning,
                      label: Text('Morning'),
                      icon: Icon(Icons.wb_sunny_outlined),
                    ),
                    ButtonSegment(
                      value: Shift.evening,
                      label: Text('Evening'),
                      icon: Icon(Icons.nights_stay_outlined),
                    ),
                  ],
                  selected: {_shift},
                  onSelectionChanged: (s) => setState(() => _shift = s.first),
                ),
                const SectionHeader('Enter liters per cow'),
                Card(
                  child: Column(
                    children: [
                      for (final c in cows)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                          child: Row(
                            children: [
                              const Text('🐄', style: TextStyle(fontSize: 26)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'avg ${store.cowAverage(c.id).toStringAsFixed(1)} L/day',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 84,
                                child: TextField(
                                  controller: _ctl(_liters, c.id),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    hintText: '0',
                                    suffixText: 'L',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 78,
                                child: TextField(
                                  controller: _ctl(_fat, c.id),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    hintText: 'fat',
                                    suffixText: '%',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _saveAll(store, cows),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    'Save ${_shift == Shift.morning ? 'morning' : 'evening'} milk',
                  ),
                ),
                const SectionHeader('Saved entries'),
                ..._entries(store),
              ],
            ),
    );
  }

  List<Widget> _entries(AppStore store) {
    final records = store.milkFor(day: _day);
    if (records.isEmpty) {
      return [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('Nothing recorded for this day.'),
          ),
        ),
      ];
    }
    return [
      Card(
        child: Column(
          children: [
            for (final r in records)
              ListTile(
                dense: true,
                leading: Text(
                  r.shift == Shift.morning ? '☀️' : '🌙',
                  style: const TextStyle(fontSize: 20),
                ),
                title: Text(store.cowById(r.cowId)?.name ?? 'Unknown'),
                subtitle: r.fat == null ? null : Text('Fat ${r.fat}%'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${qty(r.liters)} L',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        store.deleteMilk(r.id);
                        _loadedKey = '';
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ];
  }
}

class _ShiftTotal extends StatelessWidget {
  final String label;
  final double value;
  final bool active;
  const _ShiftTotal(this.label, this.value, this.active);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: active ? AppColors.sky.withValues(alpha: 0.15) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            FittedBox(child: Text(label, style: const TextStyle(fontSize: 12))),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                '${qty(value)} L',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppColors.sky,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick single-cow milk entry (used from the cow profile).
Future<void> showMilkSheet(BuildContext context, {required String cowId}) {
  final store = StoreScope.read(context);
  final liters = TextEditingController();
  final fat = TextEditingController();
  final formKey = GlobalKey<FormState>();
  DateTime day = DateTime.now();
  Shift shift = day.hour < 14 ? Shift.morning : Shift.evening;

  return showFormSheet(
    context,
    title: 'Add milk – ${store.cowById(cowId)?.name}',
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DateField(
              label: 'Date',
              value: day,
              last: DateTime.now(),
              onChanged: (d) => setS(() => day = d),
            ),
            const SizedBox(height: 12),
            SegmentedButton<Shift>(
              segments: const [
                ButtonSegment(value: Shift.morning, label: Text('Morning')),
                ButtonSegment(value: Shift.evening, label: Text('Evening')),
              ],
              selected: {shift},
              onSelectionChanged: (s) => setS(() => shift = s.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: liters,
              autofocus: true,
              validator: positiveNumber,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Liters',
                suffixText: 'L',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: fat,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Fat % (optional)'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                store.addMilk(
                  MilkRecord(
                    id: store.newId(),
                    cowId: cowId,
                    date: dateOnly(
                      day,
                    ).add(Duration(hours: shift == Shift.morning ? 6 : 18)),
                    shift: shift,
                    liters: double.parse(liters.text),
                    fat: double.tryParse(fat.text),
                  ),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    ),
  );
}
