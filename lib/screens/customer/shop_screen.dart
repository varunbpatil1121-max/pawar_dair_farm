import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class ShopScreen extends StatefulWidget {
  final VoidCallback onOrdered;
  const ShopScreen({super.key, required this.onOrdered});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final Map<String, double> _cart = {};

  double _step(Product p) => switch (p.unit) {
    'kg' || 'L' => 0.5,
    'g' || 'ml' => 250,
    _ => 1,
  };

  void _change(Product p, int dir) {
    setState(() {
      final next = (_cart[p.id] ?? 0) + _step(p) * dir;
      if (next <= 0) {
        _cart.remove(p.id);
      } else if (!p.isMilk && next > p.stock) {
        toast(context, 'Only ${qty(p.stock)} ${p.unit} available');
      } else {
        _cart[p.id] = next;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final products = store.products.where((p) => p.available).toList();
    _cart.removeWhere((id, _) => store.productById(id) == null);
    final total = _cart.entries.fold(
      0.0,
      (s, e) => s + (store.productById(e.key)!.price * e.value),
    );
    final count = _cart.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: products.isEmpty
          ? const EmptyState(
              icon: Icons.storefront_outlined,
              title: 'No products available right now',
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisExtent: 236,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, i) {
                final p = products[i];
                final inCart = _cart[p.id] ?? 0;
                final outOfStock = !p.isMilk && p.stock <= 0;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 76,
                          width: double.infinity,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            p.emoji,
                            style: const TextStyle(fontSize: 42),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${rupees(p.price)} / ${p.unit}',
                          style: const TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          outOfStock
                              ? 'Out of stock'
                              : p.isMilk
                              ? 'Fresh today'
                              : p.isLowStock
                              ? 'Only ${qty(p.stock)} left'
                              : 'In stock',
                          style: TextStyle(
                            fontSize: 11,
                            color: outOfStock || p.isLowStock
                                ? AppColors.rose
                                : AppColors.sky,
                          ),
                        ),
                        const Spacer(),
                        if (inCart == 0)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 38),
                              ),
                              onPressed: outOfStock
                                  ? null
                                  : () => _change(p, 1),
                              child: const Text('Add'),
                            ),
                          )
                        else
                          Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  color: Colors.white,
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: () => _change(p, -1),
                                ),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${qty(inCart)} ${p.unit}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  color: Colors.white,
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed: () => _change(p, 1),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomSheet: count == 0
          ? null
          : SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
                decoration: BoxDecoration(
                  color: AppColors.greenDark,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$count item${count == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            rupees(total),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.greenDark,
                        minimumSize: const Size(0, 46),
                      ),
                      onPressed: () => _checkout(store),
                      child: const Text('Checkout →'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _checkout(AppStore store) {
    final me = store.currentUser!;
    final note = TextEditingController();
    DateTime delivery = dateOnly(DateTime.now()).add(const Duration(days: 1));
    final items = [
      for (final e in _cart.entries)
        if (store.productById(e.key) case final p?)
          OrderItem(
            productId: p.id,
            productName: p.name,
            unit: p.unit,
            quantity: e.value,
            rate: p.price,
          ),
    ];
    final total = items.fold(0.0, (s, i) => s + i.total);

    showFormSheet(
      context,
      title: 'Confirm order',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final i in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${i.productName} × ${qty(i.quantity)} ${i.unit}',
                      ),
                    ),
                    Text(
                      rupees(i.total),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            const Divider(height: 24),
            Row(
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  rupees(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Delivery day', style: Theme.of(ctx).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (var d = 0; d < 4; d++)
                  ChoiceChip(
                    label: Text(
                      d == 0
                          ? 'Today'
                          : d == 1
                          ? 'Tomorrow'
                          : fmtDay(
                              dateOnly(DateTime.now()).add(Duration(days: d)),
                            ),
                    ),
                    selected: sameDay(
                      delivery,
                      DateTime.now().add(Duration(days: d)),
                    ),
                    onSelected: (_) => setS(
                      () => delivery = dateOnly(
                        DateTime.now(),
                      ).add(Duration(days: d)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: const InputDecoration(
                labelText: 'Note for the farm (optional)',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount will be added to your monthly bill. Pay anytime.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                store.placeOrder(
                  Order(
                    id: store.newId(),
                    customerId: me.id,
                    customerName: me.name,
                    items: items,
                    createdAt: DateTime.now(),
                    deliveryDate: delivery,
                    note: note.text.trim(),
                  ),
                );
                Navigator.pop(ctx);
                setState(_cart.clear);
                toast(context, 'Order placed! 🎉 The farm will confirm soon.');
                widget.onOrdered();
              },
              child: const Text('Place order'),
            ),
          ],
        ),
      ),
    );
  }
}
