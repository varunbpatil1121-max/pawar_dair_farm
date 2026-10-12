import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Daily delivery route: every subscribed customer for the chosen day, with a
/// one-tap "delivered" check that books the milk on their account.
class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({super.key});

  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
  DateTime _day = dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final subs = store.subscribersFor(_day);
    final skipped = store.customers
        .where((c) => c.active && c.dailyLiters > 0 && c.skips(_day))
        .toList();
    final done = subs.where((c) => store.deliveredTo(c.id, _day)).length;
    final totalL = subs.fold(0.0, (s, c) => s + c.dailyLiters);
    final progress = subs.isEmpty ? 1.0 : done / subs.length;
    final isToday = sameDay(_day, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deliveries'),
        actions: [
          if (subs.isNotEmpty &&
              done < subs.length &&
              !_day.isAfter(DateTime.now()))
            TextButton.icon(
              onPressed: () async {
                if (await confirm(
                  context,
                  'Mark all delivered?',
                  'Books ${qty(totalL)} L on ${subs.length - done} customer accounts.',
                  action: 'Mark all',
                )) {
                  for (final c in subs) {
                    store.markDelivered(c, _day);
                  }
                }
              },
              icon: const Icon(Icons.done_all),
              label: const Text('All'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
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
                  child: Text(
                    isToday ? 'Today • ${fmtShortDate(_day)}' : fmtDay(_day),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () =>
                      setState(() => _day = _day.add(const Duration(days: 1))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$done of ${subs.length} delivered',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${qty(totalL)} L needed',
                        style: const TextStyle(
                          color: AppColors.sky,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      color: AppColors.teal,
                      backgroundColor: AppColors.teal.withValues(alpha: 0.15),
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Milk in can right now: ${qty(store.milkAvailableToday())} L',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (subs.isEmpty)
            const EmptyState(
              icon: Icons.delivery_dining_outlined,
              title: 'No deliveries for this day',
              message:
                  'Set "Liters per day" on a customer to add them to the route',
            )
          else
            Card(
              child: Column(
                children: [
                  for (final c in subs) _DeliveryTile(c: c, day: _day),
                ],
              ),
            ),
          if (skipped.isNotEmpty) ...[
            const SectionHeader('Paused by customer'),
            Card(
              child: Column(
                children: [
                  for (final c in skipped)
                    ListTile(
                      leading: const Icon(
                        Icons.pause_circle_outline,
                        color: AppColors.amber,
                      ),
                      title: Text(c.name),
                      subtitle: Text('${qty(c.dailyLiters)} L skipped'),
                      trailing: TextButton(
                        onPressed: () => store.toggleSkip(c, _day),
                        child: const Text('Resume'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeliveryTile extends StatelessWidget {
  final AppUser c;
  final DateTime day;
  const _DeliveryTile({required this.c, required this.day});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final delivered = store.deliveredTo(c.id, day);
    final product =
        store.productById(c.subscriptionProductId) ?? store.milkProduct;
    final future = dateOnly(day).isAfter(dateOnly(DateTime.now()));
    return CheckboxListTile(
      value: delivered,
      onChanged: future
          ? null
          : (v) => v == true
                ? store.markDelivered(c, day)
                : store.undoDelivery(c.id, day),
      activeColor: AppColors.teal,
      title: Text(
        c.name,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          decoration: delivered ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        '${qty(c.dailyLiters)} L ${product?.name ?? ''}${c.address.isEmpty ? '' : '\n${c.address}'}',
      ),
      isThreeLine: c.address.isNotEmpty,
      secondary: CircleAvatar(
        backgroundColor: (delivered ? AppColors.teal : AppColors.sky)
            .withValues(alpha: 0.15),
        child: Text(product?.emoji ?? '🥛'),
      ),
    );
  }
}
