import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'admin_shell.dart';
import 'deliveries_screen.dart';
import 'orders_screen.dart';
import 'products_screen.dart';
import 'customers_screen.dart';
import 'sales_screen.dart';
import 'vaccinations_screen.dart';
import '../feed/feed_screen.dart';
import '../feed/hygiene_screen.dart';

class DashboardScreen extends StatelessWidget {
  final ValueChanged<int> onTab;
  const DashboardScreen({super.key, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final today = dateOnly(now);
    final collected = store.litersCollectedOn(now);
    final morning = store.litersCollectedOn(now, shift: Shift.morning);
    final evening = store.litersCollectedOn(now, shift: Shift.evening);
    final sold = store.litersSoldOn(now);
    final revenue = store.revenueOn(now);
    final yRevenue = store.revenueOn(today.subtract(const Duration(days: 1)));
    final subs = store.subscribersFor(now);
    final delivered = subs.where((c) => store.deliveredTo(c.id, now)).length;
    final upcoming = store.upcomingVaccinations.take(4).toList();
    final lowStock = store.products.where((p) => p.isLowStock).toList();
    final pending = store.pendingOrderCount;

    final week = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    final change = yRevenue == 0 ? null : (revenue - yRevenue) / yRevenue * 100;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${greeting()}, ${store.currentUser!.name} 👋',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${store.farmName} • ${fmtDay(now)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Logout',
                  onPressed: store.logout,
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Hero card
            HeroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Today\'s milk',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                      ),
                      Pill(
                        '${store.cows.where((c) => c.status == CowStatus.milking).length} cows milking',
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${qty(collected)} L',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _HeroStat('☀️ Morning', '${qty(morning)} L'),
                      _HeroStat('🌙 Evening', '${qty(evening)} L'),
                      _HeroStat('🛒 Sold', '${qty(sold)} L'),
                      _HeroStat(
                        '🥛 In can',
                        '${qty(store.milkAvailableToday())} L',
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
                  label: 'Earned today',
                  value: rupees(revenue),
                  icon: Icons.currency_rupee,
                  color: AppColors.green,
                  subtitle: change == null
                      ? null
                      : '${change >= 0 ? '▲' : '▼'} ${change.abs().toStringAsFixed(0)}% vs yesterday',
                  onTap: () => onTab(3),
                ),
                StatCard(
                  label: 'Customer dues',
                  value: rupees(store.totalDues),
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.rose,
                  subtitle: 'Tap to collect',
                  onTap: () => push(context, const CustomersScreen()),
                ),
                StatCard(
                  label: 'Deliveries',
                  value: '$delivered / ${subs.length}',
                  icon: Icons.delivery_dining,
                  color: AppColors.teal,
                  subtitle: delivered == subs.length
                      ? 'All done ✓'
                      : '${subs.length - delivered} remaining',
                  onTap: () => push(context, const DeliveriesScreen()),
                ),
                StatCard(
                  label: 'New orders',
                  value: '$pending',
                  icon: Icons.receipt_long,
                  color: AppColors.amber,
                  subtitle: pending > 0 ? 'Needs action' : 'All clear',
                  onTap: () => push(context, const OrdersScreen()),
                ),
              ],
            ),

            // Quick actions
            const SectionHeader('Quick actions'),
            Row(
              children: [
                _QuickAction(
                  Icons.water_drop,
                  'Add milk',
                  AppColors.sky,
                  () => onTab(2),
                ),
                _QuickAction(
                  Icons.add_shopping_cart,
                  'New sale',
                  AppColors.green,
                  () => showAddSaleSheet(context),
                ),
                _QuickAction(
                  Icons.add_a_photo,
                  'Post',
                  AppColors.rose,
                  () => openComposer(context),
                ),
                _QuickAction(
                  Icons.clean_hands,
                  'Hygiene',
                  AppColors.teal,
                  () => push(context, const HygieneScreen(editable: true)),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const TrustCard(admin: true),

            // Alerts
            if (upcoming.isNotEmpty || lowStock.isNotEmpty) ...[
              SectionHeader(
                'Alerts',
                action: 'All vaccines',
                onAction: () => push(context, const VaccinationsScreen()),
              ),
              Card(
                child: Column(
                  children: [
                    for (final v in upcoming)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              (v.isOverdue ? AppColors.rose : AppColors.amber)
                                  .withValues(alpha: 0.15),
                          child: Icon(
                            Icons.vaccines,
                            color: v.isOverdue
                                ? AppColors.rose
                                : AppColors.amber,
                          ),
                        ),
                        title: Text(
                          '${store.cowById(v.cowId)?.name ?? ''} • ${v.vaccine}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(fmtDate(v.dueDate)),
                        trailing: Pill(
                          dueLabel(v),
                          color: v.isOverdue ? AppColors.rose : AppColors.amber,
                        ),
                        onTap: () => push(context, const VaccinationsScreen()),
                      ),
                    for (final p in lowStock)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.violet.withValues(
                            alpha: 0.15,
                          ),
                          child: Text(p.emoji),
                        ),
                        title: Text('${p.name} is running low'),
                        subtitle: Text('Only ${qty(p.stock)} ${p.unit} left'),
                        trailing: const Pill(
                          'Restock',
                          color: AppColors.violet,
                        ),
                        onTap: () => push(context, const ProductsScreen()),
                      ),
                  ],
                ),
              ),
            ],

            // Charts
            const SectionHeader('Milk collected – last 7 days'),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                child: MiniBarChart(
                  color: AppColors.sky,
                  format: (v) => qty(v.round()),
                  data: [
                    for (final d in week)
                      BarDatum(fmtWeekday(d), store.litersCollectedOn(d)),
                  ],
                ),
              ),
            ),
            const SectionHeader('Sales – last 7 days'),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                child: MiniBarChart(
                  color: AppColors.green,
                  format: (v) => v >= 1000
                      ? '${(v / 1000).toStringAsFixed(1)}k'
                      : v.round().toString(),
                  data: [
                    for (final d in week)
                      BarDatum(fmtWeekday(d), store.revenueOn(d)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String fmtWeekday(DateTime d) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];

String dueLabel(Vaccination v) {
  final d = v.daysUntilDue;
  if (v.isDone) return 'Done';
  if (d < 0) return '${-d}d overdue';
  if (d == 0) return 'Today';
  if (d == 1) return 'Tomorrow';
  return 'In $d days';
}

class _HeroStat extends StatelessWidget {
  final String label, value;
  const _HeroStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
