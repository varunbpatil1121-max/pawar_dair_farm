import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

IconData expenseIcon(String c) => switch (c) {
  'Feed & Fodder' => Icons.grass,
  'Medicine & Vet' => Icons.medical_services_outlined,
  'Labour' => Icons.engineering_outlined,
  'Electricity' => Icons.bolt,
  'Equipment' => Icons.build_outlined,
  'Transport' => Icons.local_shipping_outlined,
  _ => Icons.receipt_outlined,
};

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final next = DateTime(_month.year, _month.month + 1);
    final list =
        store.expenses
            .where((e) => !e.date.isBefore(_month) && e.date.isBefore(next))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final total = list.fold(0.0, (s, e) => s + e.amount);
    final byCat = <String, double>{};
    for (final e in list) {
      byCat[e.category] = (byCat[e.category] ?? 0) + e.amount;
    }
    final cats = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => showExpenseSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          Card(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(
                    () => _month = DateTime(_month.year, _month.month - 1),
                  ),
                ),
                Expanded(
                  child: Text(
                    fmtMonth(_month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: next.isAfter(DateTime.now())
                      ? null
                      : () => setState(() => _month = next),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StatCard(
            label: 'Spent this month',
            value: rupees(total),
            icon: Icons.trending_down,
            color: AppColors.rose,
          ),
          if (cats.isNotEmpty) ...[
            const SectionHeader('By category'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (final e in cats)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(expenseIcon(e.key), size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(e.key)),
                                Text(
                                  rupees(e.value),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: e.value / total,
                                minHeight: 8,
                                color: Colors.brown,
                                backgroundColor: Colors.brown.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SectionHeader('Entries'),
          if (list.isEmpty)
            const EmptyState(
              icon: Icons.receipt_outlined,
              title: 'No expenses this month',
            )
          else
            Card(
              child: Column(
                children: [
                  for (final e in list)
                    ListTile(
                      onTap: () => showExpenseSheet(context, expense: e),
                      leading: CircleAvatar(
                        backgroundColor: Colors.brown.withValues(alpha: 0.12),
                        child: Icon(
                          expenseIcon(e.category),
                          color: Colors.brown,
                        ),
                      ),
                      title: Text(e.category),
                      subtitle: Text(
                        '${fmtShortDate(e.date)}${e.note.isEmpty ? '' : ' • ${e.note}'}',
                      ),
                      trailing: Text(
                        rupees(e.amount),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> showExpenseSheet(BuildContext context, {Expense? expense}) {
  final store = StoreScope.read(context);
  final formKey = GlobalKey<FormState>();
  final amount = TextEditingController(
    text: expense == null ? '' : qty(expense.amount),
  );
  final note = TextEditingController(text: expense?.note);
  String cat = expense?.category ?? expenseCategories.first;
  DateTime date = expense?.date ?? DateTime.now();

  return showFormSheet(
    context,
    title: expense == null ? 'Add expense' : 'Edit expense',
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in expenseCategories)
                  ChoiceChip(
                    avatar: Icon(expenseIcon(c), size: 18),
                    label: Text(c),
                    selected: cat == c,
                    onSelected: (_) => setS(() => cat = c),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: amount,
              validator: positiveNumber,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 12),
            DateField(
              label: 'Date',
              value: date,
              last: DateTime.now(),
              onChanged: (d) => setS(() => date = d),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final e = Expense(
                  id: expense?.id ?? store.newId(),
                  category: cat,
                  amount: double.parse(amount.text),
                  date: date,
                  note: note.text.trim(),
                );
                store.upsert(store.expenses, e, (x) => x.id == e.id);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
            if (expense != null)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.rose),
                onPressed: () {
                  store.expenses.removeWhere((x) => x.id == expense.id);
                  store.save();
                  Navigator.pop(ctx);
                },
                child: const Text('Delete'),
              ),
          ],
        ),
      ),
    ),
  );
}
