import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

Color orderColor(OrderStatus s) => switch (s) {
  OrderStatus.pending => AppColors.amber,
  OrderStatus.accepted => AppColors.sky,
  OrderStatus.delivered => AppColors.green,
  OrderStatus.cancelled => Colors.grey,
};

String orderLabel(OrderStatus s) => switch (s) {
  OrderStatus.pending => 'New',
  OrderStatus.accepted => 'Accepted',
  OrderStatus.delivered => 'Delivered',
  OrderStatus.cancelled => 'Cancelled',
};

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    List<Order> by(List<OrderStatus> s) =>
        store.orders.where((o) => s.contains(o.status)).toList()
          ..sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
    final active = by([OrderStatus.pending, OrderStatus.accepted]);
    final past = by([
      OrderStatus.delivered,
      OrderStatus.cancelled,
    ]).reversed.toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customer orders'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Active (${active.length})'),
              Tab(text: 'Completed (${past.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _list(active, 'No active orders', admin: true),
            _list(past, 'No completed orders yet', admin: true),
          ],
        ),
      ),
    );
  }

  Widget _list(List<Order> orders, String empty, {required bool admin}) =>
      orders.isEmpty
      ? EmptyState(icon: Icons.receipt_long_outlined, title: empty)
      : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => OrderCard(order: orders[i], admin: admin),
        );
}

class OrderCard extends StatelessWidget {
  final Order order;
  final bool admin;
  const OrderCard({super.key, required this.order, required this.admin});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final o = order;
    final color = orderColor(o.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    admin
                        ? o.customerName
                        : 'Order #${o.id.substring(o.id.length - 5).toUpperCase()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                Pill(orderLabel(o.status), color: color),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Deliver on ${fmtDay(o.deliveryDate)} • placed ${fmtShortDate(o.createdAt)} ${fmtTime(o.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 20),
            for (final i in o.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text(store.productById(i.productId)?.emoji ?? '🛒'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${i.productName} × ${qty(i.quantity)} ${i.unit}',
                      ),
                    ),
                    Text(
                      rupees(i.total),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            if (o.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '📝 ${o.note}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            const Divider(height: 20),
            Row(
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  rupees(o.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
            if (admin &&
                (o.status == OrderStatus.pending ||
                    o.status == OrderStatus.accepted)) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.rose,
                        minimumSize: const Size(0, 46),
                      ),
                      onPressed: () async {
                        if (await confirm(
                          context,
                          'Cancel order?',
                          'The customer will see it as cancelled.',
                          action: 'Cancel order',
                        )) {
                          store.setOrderStatus(o, OrderStatus.cancelled);
                        }
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 46),
                      ),
                      onPressed: () {
                        if (o.status == OrderStatus.pending) {
                          store.setOrderStatus(o, OrderStatus.accepted);
                          toast(context, 'Order accepted');
                        } else {
                          store.setOrderStatus(o, OrderStatus.delivered);
                          toast(
                            context,
                            '${rupees(o.total)} added to ${o.customerName}\'s account',
                          );
                        }
                      },
                      child: Text(
                        o.status == OrderStatus.pending
                            ? 'Accept'
                            : 'Mark delivered',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (!admin && o.status == OrderStatus.pending) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppColors.rose),
                  onPressed: () =>
                      store.setOrderStatus(o, OrderStatus.cancelled),
                  child: const Text('Cancel order'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
