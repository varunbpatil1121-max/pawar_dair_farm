import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final next = DateTime(_month.year, _month.month + 1);
    final revenue = store.revenueBetween(_month, next);
    final spent = store.expensesBetween(_month, next);
    final profit = revenue - spent;
    final liters = store.litersCollectedBetween(_month, next);
    final daysElapsed = next.isAfter(DateTime.now())
        ? DateTime.now().day
        : next.subtract(const Duration(days: 1)).day;

    // Revenue by product
    final byProduct = <String, double>{};
    for (final s in store.sales.where(
      (s) => !s.date.isBefore(_month) && s.date.isBefore(next),
    )) {
      byProduct[s.productName] = (byProduct[s.productName] ?? 0) + s.total;
    }
    final products = byProduct.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Top cows
    final cowTotals = <String, double>{};
    for (final m in store.milk.where(
      (m) => !m.date.isBefore(_month) && m.date.isBefore(next),
    )) {
      cowTotals[m.cowId] = (cowTotals[m.cowId] ?? 0) + m.liters;
    }
    final topCows = cowTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Top customers
    final custTotals = <String, double>{};
    for (final s in store.sales.where(
      (s) =>
          s.customerId != null &&
          !s.date.isBefore(_month) &&
          s.date.isBefore(next),
    )) {
      custTotals[s.customerId!] = (custTotals[s.customerId!] ?? 0) + s.total;
    }
    final topCust = custTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Last 6 months profit trend
    final months = [
      for (var i = 5; i >= 0; i--)
        DateTime(DateTime.now().year, DateTime.now().month - i),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
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
          HeroCard(
            colors: profit >= 0 ? AppColors.heroGradient : HeroCard.danger,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profit >= 0 ? 'Net profit' : 'Net loss',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  rupees(profit.abs()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _kv('Income', rupees(revenue))),
                    Expanded(child: _kv('Expenses', rupees(spent))),
                    Expanded(
                      child: _kv(
                        'Margin',
                        revenue == 0
                            ? '—'
                            : '${(profit / revenue * 100).toStringAsFixed(0)}%',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ResponsiveGrid(
            children: [
              StatCard(
                label: 'Milk collected',
                value: '${qty(liters.round())} L',
                icon: Icons.water_drop,
                color: AppColors.sky,
                subtitle:
                    '${(liters / daysElapsed).toStringAsFixed(1)} L/day avg',
              ),
              StatCard(
                label: 'Cost per liter',
                value: liters == 0 ? '—' : rupees(spent / liters),
                icon: Icons.calculate_outlined,
                color: AppColors.amber,
                subtitle: 'Expenses ÷ liters',
              ),
            ],
          ),
          const SectionHeader('Profit – last 6 months'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              child: MiniBarChart(
                color: AppColors.green,
                format: (v) => v >= 1000
                    ? '${(v / 1000).toStringAsFixed(1)}k'
                    : v.round().toString(),
                data: [
                  for (final m in months)
                    BarDatum(
                      fmtMonth(m).substring(0, 3),
                      (store.revenueBetween(m, DateTime(m.year, m.month + 1)) -
                              store.expensesBetween(
                                m,
                                DateTime(m.year, m.month + 1),
                              ))
                          .clamp(0, double.infinity)
                          .toDouble(),
                    ),
                ],
              ),
            ),
          ),
          if (products.isNotEmpty) ...[
            const SectionHeader('Income by product'),
            Card(
              child: Column(
                children: [
                  for (final p in products)
                    ListTile(
                      dense: true,
                      title: Text(p.key),
                      subtitle: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: p.value / revenue,
                          minHeight: 6,
                          color: AppColors.green,
                          backgroundColor: AppColors.green.withValues(
                            alpha: 0.12,
                          ),
                        ),
                      ),
                      trailing: Text(
                        rupees(p.value),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (topCows.isNotEmpty) ...[
            const SectionHeader('🏆 Top milking cows'),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < topCows.length && i < 5; i++)
                    ListTile(
                      leading: Text(
                        ['🥇', '🥈', '🥉', '4️⃣', '5️⃣'][i],
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        store.cowById(topCows[i].key)?.name ?? 'Removed cow',
                      ),
                      trailing: Text(
                        '${qty(topCows[i].value.round())} L',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.sky,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (topCust.isNotEmpty) ...[
            const SectionHeader('Top customers'),
            Card(
              child: Column(
                children: [
                  for (final c in topCust.take(5))
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(store.userById(c.key)?.name ?? 'Customer'),
                      trailing: Text(
                        rupees(c.value),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SectionHeader('Herd summary'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in CowStatus.values)
                    Chip(
                      label: Text(
                        '${s.name[0].toUpperCase()}${s.name.substring(1)}: ${store.cows.where((c) => c.status == s).length}',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(k, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      FittedBox(
        child: Text(
          v,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    ],
  );
}
