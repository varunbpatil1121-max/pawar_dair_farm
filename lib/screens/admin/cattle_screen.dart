import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'admin_shell.dart';
import 'dashboard_screen.dart';
import 'milk_screen.dart';

Color cowStatusColor(CowStatus s) => switch (s) {
  CowStatus.milking => AppColors.green,
  CowStatus.dry => Colors.brown,
  CowStatus.pregnant => AppColors.violet,
  CowStatus.calf => AppColors.sky,
  CowStatus.sick => AppColors.rose,
};

String cowStatusLabel(CowStatus s) => switch (s) {
  CowStatus.milking => 'Milking',
  CowStatus.dry => 'Dry',
  CowStatus.pregnant => 'Pregnant',
  CowStatus.calf => 'Calf',
  CowStatus.sick => 'Sick',
};

class CattleScreen extends StatefulWidget {
  const CattleScreen({super.key});

  @override
  State<CattleScreen> createState() => _CattleScreenState();
}

class _CattleScreenState extends State<CattleScreen> {
  CowStatus? _filter;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cows =
        store.cows
            .where((c) => _filter == null || c.status == _filter)
            .where(
              (c) =>
                  _query.isEmpty ||
                  c.name.toLowerCase().contains(_query) ||
                  c.tagNumber.toLowerCase().contains(_query) ||
                  c.breed.toLowerCase().contains(_query),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(title: Text('Cattle (${store.cows.length})')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => showCowSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add cow'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search name, tag or breed',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                ),
                for (final s in CowStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        '${cowStatusLabel(s)} (${store.cows.where((c) => c.status == s).length})',
                      ),
                      selected: _filter == s,
                      onSelected: (_) => setState(() => _filter = s),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: cows.isEmpty
                ? const EmptyState(
                    icon: Icons.pets,
                    title: 'No cattle here',
                    message: 'Tap "Add cow" to register your animals',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: cows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = cows[i];
                      final avg = store.cowAverage(c.id);
                      final dueVacc = store
                          .vaccinationsFor(c.id)
                          .where((v) => !v.isDone && v.daysUntilDue <= 7)
                          .length;
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () =>
                              push(context, CowDetailScreen(cowId: c.id)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: cowStatusColor(
                                    c.status,
                                  ).withValues(alpha: 0.15),
                                  child: Text(
                                    c.status == CowStatus.calf ? '🐮' : '🐄',
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              c.name,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          if (dueVacc > 0) ...[
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.vaccines,
                                              size: 18,
                                              color: AppColors.rose,
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${c.tagNumber} • ${c.breed} • ${c.ageLabel}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Pill(
                                        cowStatusLabel(c.status),
                                        color: cowStatusColor(c.status),
                                      ),
                                    ],
                                  ),
                                ),
                                if (avg > 0)
                                  Column(
                                    children: [
                                      Text(
                                        qty(
                                          double.parse(avg.toStringAsFixed(1)),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.sky,
                                        ),
                                      ),
                                      const Text(
                                        'L/day',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
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

class CowDetailScreen extends StatelessWidget {
  final String cowId;
  const CowDetailScreen({super.key, required this.cowId});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cow = store.cowById(cowId);
    if (cow == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.pets, title: 'Cow removed'),
      );
    }
    final today = dateOnly(DateTime.now());
    final week = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    final records = store.milkFor(cowId: cow.id);
    final vaccs = store.vaccinationsFor(cow.id);
    final monthTotal = records
        .where((r) => r.date.month == today.month && r.date.year == today.year)
        .fold(0.0, (s, r) => s + r.liters);
    final fats = records
        .where((r) => r.fat != null)
        .take(14)
        .map((r) => r.fat!);
    final avgFat = fats.isEmpty
        ? null
        : fats.reduce((a, b) => a + b) / fats.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(cow.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showCowSheet(context, cow: cow),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await confirm(
                context,
                'Delete ${cow.name}?',
                'Milk and vaccination records for this cow will also be deleted.',
              )) {
                store.deleteCow(cow.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => showVaccinationSheet(context, cowId: cow.id),
        icon: const Icon(Icons.vaccines),
        label: const Text('Add vaccine'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: cowStatusColor(
                      cow.status,
                    ).withValues(alpha: 0.15),
                    child: const Text('🐄', style: TextStyle(fontSize: 38)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tag ${cow.tagNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text('${cow.breed} • ${cow.ageLabel}'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Pill(
                              cowStatusLabel(cow.status),
                              color: cowStatusColor(cow.status),
                            ),
                            if (cow.expectedCalvingDate != null)
                              Pill(
                                'Calving ${fmtShortDate(cow.expectedCalvingDate!)}',
                                color: AppColors.violet,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ResponsiveGrid(
            children: [
              StatCard(
                label: 'Avg per day (7d)',
                value: '${store.cowAverage(cow.id).toStringAsFixed(1)} L',
                icon: Icons.water_drop,
                color: AppColors.sky,
              ),
              StatCard(
                label: 'This month',
                value: '${qty(monthTotal.round())} L',
                icon: Icons.calendar_month,
                color: AppColors.green,
              ),
              StatCard(
                label: 'Avg fat',
                value: avgFat == null ? '—' : '${avgFat.toStringAsFixed(1)}%',
                icon: Icons.opacity,
                color: AppColors.amber,
              ),
              StatCard(
                label: 'Last calving',
                value: cow.lastCalvingDate == null
                    ? '—'
                    : fmtShortDate(cow.lastCalvingDate!),
                icon: Icons.child_friendly_outlined,
                color: AppColors.violet,
              ),
            ],
          ),
          if (cow.notes.isNotEmpty) ...[
            const SectionHeader('Notes'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(cow.notes),
              ),
            ),
          ],
          SectionHeader(
            'Milk – last 7 days',
            action: 'Add milk',
            onAction: () => showMilkSheet(context, cowId: cow.id),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              child: MiniBarChart(
                color: AppColors.sky,
                height: 140,
                format: (v) => v.toStringAsFixed(1),
                data: [
                  for (final d in week)
                    BarDatum(
                      fmtWeekday(d),
                      store
                          .milkFor(cowId: cow.id, day: d)
                          .fold(0.0, (s, r) => s + r.liters),
                    ),
                ],
              ),
            ),
          ),
          const SectionHeader('Vaccinations & health'),
          if (vaccs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No vaccination records yet.'),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final v in vaccs) VaccinationTile(v: v, showCow: false),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class VaccinationTile extends StatelessWidget {
  final Vaccination v;
  final bool showCow;
  const VaccinationTile({super.key, required this.v, this.showCow = true});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final color = v.isDone
        ? AppColors.green
        : v.isOverdue
        ? AppColors.rose
        : v.daysUntilDue <= 7
        ? AppColors.amber
        : AppColors.sky;
    final cow = store.cowById(v.cowId);
    return ListTile(
      onTap: () => showVaccinationSheet(context, cowId: v.cowId, existing: v),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(v.isDone ? Icons.check : Icons.vaccines, color: color),
      ),
      title: Text(
        showCow ? '${cow?.name ?? '?'} • ${v.vaccine}' : v.vaccine,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        v.isDone
            ? 'Given ${fmtDate(v.doneDate!)}${v.vet.isEmpty ? '' : ' • ${v.vet}'}'
            : 'Due ${fmtDate(v.dueDate)}${v.vet.isEmpty ? '' : ' • ${v.vet}'}',
      ),
      trailing: v.isDone
          ? Pill('Done', color: color)
          : FilledButton.tonal(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
              onPressed: () {
                v.doneDate = DateTime.now();
                store.save();
                toast(context, '${v.vaccine} marked as given');
              },
              child: const Text('Mark done'),
            ),
    );
  }
}

const _breeds = [
  'Gir',
  'Sahiwal',
  'HF Cross',
  'Jersey',
  'Red Sindhi',
  'Tharparkar',
  'Khillar',
  'Murrah (Buffalo)',
  'Other',
];

Future<void> showCowSheet(BuildContext context, {Cow? cow}) {
  final store = StoreScope.read(context);
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: cow?.name);
  final tag = TextEditingController(
    text:
        cow?.tagNumber ??
        'PDF-${(store.cows.length + 1).toString().padLeft(3, '0')}',
  );
  final notes = TextEditingController(text: cow?.notes);
  String breed = cow?.breed ?? 'Gir';
  CowStatus status = cow?.status ?? CowStatus.milking;
  DateTime? birth = cow?.birthDate;
  DateTime? lastCalving = cow?.lastCalvingDate;
  DateTime? expectedCalving = cow?.expectedCalvingDate;

  return showFormSheet(
    context,
    title: cow == null ? 'Add new cow' : 'Edit ${cow.name}',
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: name,
              validator: requiredField,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.pets),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: tag,
              decoration: const InputDecoration(
                labelText: 'Tag / ear number',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _breeds.contains(breed) ? breed : 'Other',
              decoration: const InputDecoration(labelText: 'Breed'),
              items: [
                for (final b in _breeds)
                  DropdownMenuItem(value: b, child: Text(b)),
              ],
              onChanged: (v) => breed = v ?? breed,
            ),
            const SizedBox(height: 12),
            Text('Status', style: Theme.of(ctx).textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final s in CowStatus.values)
                  ChoiceChip(
                    label: Text(cowStatusLabel(s)),
                    selected: status == s,
                    onSelected: (_) => setS(() => status = s),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DateField(
              label: 'Date of birth',
              value: birth,
              last: DateTime.now(),
              onChanged: (d) => setS(() => birth = d),
            ),
            const SizedBox(height: 12),
            DateField(
              label: 'Last calving date',
              value: lastCalving,
              last: DateTime.now(),
              onChanged: (d) => setS(() => lastCalving = d),
            ),
            if (status == CowStatus.pregnant) ...[
              const SizedBox(height: 12),
              DateField(
                label: 'Expected calving date',
                value: expectedCalving,
                first: DateTime.now().subtract(const Duration(days: 30)),
                onChanged: (d) => setS(() => expectedCalving = d),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: notes,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final c = Cow(
                  id: cow?.id ?? store.newId(),
                  name: name.text.trim(),
                  tagNumber: tag.text.trim(),
                  breed: breed,
                  birthDate: birth,
                  status: status,
                  notes: notes.text.trim(),
                  lastCalvingDate: lastCalving,
                  expectedCalvingDate: status == CowStatus.pregnant
                      ? expectedCalving
                      : null,
                );
                store.upsert(store.cows, c, (x) => x.id == c.id);
                Navigator.pop(ctx);
              },
              child: Text(cow == null ? 'Add cow' : 'Save changes'),
            ),
          ],
        ),
      ),
    ),
  );
}

const commonVaccines = [
  'FMD (Foot & Mouth)',
  'HS (Haemorrhagic Septicaemia)',
  'BQ (Black Quarter)',
  'Brucellosis',
  'Lumpy Skin (LSD)',
  'Theileriosis',
  'Anthrax',
  'Deworming',
];

Future<void> showVaccinationSheet(
  BuildContext context, {
  String? cowId,
  Vaccination? existing,
}) {
  final store = StoreScope.read(context);
  final formKey = GlobalKey<FormState>();
  final vaccine = TextEditingController(text: existing?.vaccine);
  final vet = TextEditingController(text: existing?.vet);
  final notes = TextEditingController(text: existing?.notes);
  String? selectedCow = existing?.cowId ?? cowId ?? store.cows.firstOrNull?.id;
  DateTime due =
      existing?.dueDate ?? DateTime.now().add(const Duration(days: 1));
  bool done = existing?.isDone ?? false;
  bool applyAll = false;

  if (store.cows.isEmpty) {
    toast(context, 'Add a cow first');
    return Future.value();
  }

  return showFormSheet(
    context,
    title: existing == null ? 'Schedule vaccination' : 'Edit vaccination',
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (existing == null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Apply to all cattle'),
                subtitle: const Text('Herd-wide vaccination drive'),
                value: applyAll,
                onChanged: (v) => setS(() => applyAll = v),
              ),
            if (!applyAll)
              DropdownButtonFormField<String>(
                initialValue: selectedCow,
                decoration: const InputDecoration(labelText: 'Cow'),
                items: [
                  for (final c in store.cows)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.name} (${c.tagNumber})'),
                    ),
                ],
                onChanged: (v) => selectedCow = v,
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: vaccine,
              validator: requiredField,
              decoration: const InputDecoration(
                labelText: 'Vaccine / treatment',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final v in commonVaccines)
                  ActionChip(
                    label: Text(v, style: const TextStyle(fontSize: 12)),
                    onPressed: () => setS(() => vaccine.text = v),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DateField(
              label: 'Due date',
              value: due,
              first: DateTime.now().subtract(const Duration(days: 365)),
              onChanged: (d) => setS(() => due = d),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: vet,
              decoration: const InputDecoration(
                labelText: 'Vet name (optional)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notes,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Already given'),
              value: done,
              onChanged: (v) => setS(() => done = v ?? false),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final targets = applyAll
                    ? store.cows.map((c) => c.id).toList()
                    : [selectedCow!];
                for (final cid in targets) {
                  final v = Vaccination(
                    id: existing?.id ?? store.newId(),
                    cowId: cid,
                    vaccine: vaccine.text.trim(),
                    dueDate: due,
                    doneDate: done
                        ? (existing?.doneDate ?? DateTime.now())
                        : null,
                    vet: vet.text.trim(),
                    notes: notes.text.trim(),
                  );
                  store.upsert(store.vaccinations, v, (x) => x.id == v.id);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
            if (existing != null)
              TextButton(
                onPressed: () {
                  store.vaccinations.removeWhere((x) => x.id == existing.id);
                  store.save();
                  Navigator.pop(ctx);
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.rose),
                child: const Text('Delete record'),
              ),
          ],
        ),
      ),
    ),
  );
}
