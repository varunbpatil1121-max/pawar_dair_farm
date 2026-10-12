import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final products = store.products;
    return Scaffold(
      appBar: AppBar(title: const Text('Products & stock')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => showProductSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      body: products.isEmpty
          ? const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products yet',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final p = products[i];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => showProductSheet(context, product: p),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.cream,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              p.emoji,
                              style: const TextStyle(fontSize: 30),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${rupees(p.price)} / ${p.unit}',
                                  style: const TextStyle(
                                    color: AppColors.green,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    if (p.isMilk)
                                      Pill(
                                        'From daily milking • ${qty(store.milkAvailableToday())} L in can',
                                        color: AppColors.sky,
                                      )
                                    else
                                      Pill(
                                        'Stock ${qty(p.stock)} ${p.unit}',
                                        color: p.isLowStock
                                            ? AppColors.rose
                                            : AppColors.green,
                                      ),
                                    if (!p.available)
                                      const Pill('Hidden', color: Colors.grey),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!p.isMilk)
                            IconButton.filledTonal(
                              tooltip: 'Add stock',
                              icon: const Icon(Icons.add),
                              onPressed: () => _restock(context, store, p),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _restock(BuildContext context, AppStore store, Product p) {
    final ctl = TextEditingController();
    showFormSheet(
      context,
      title: 'Add stock – ${p.name}',
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Current stock: ${qty(p.stock)} ${p.unit}'),
          const SizedBox(height: 12),
          TextField(
            controller: ctl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Quantity made / added',
              suffixText: p.unit,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final n = double.tryParse(ctl.text);
              if (n == null || n <= 0) return;
              p.stock += n;
              store.save();
              Navigator.pop(ctx);
              toast(context, 'Stock updated to ${qty(p.stock)} ${p.unit}');
            },
            child: const Text('Add to stock'),
          ),
        ],
      ),
    );
  }
}

const _emojis = [
  '🥛',
  '🍼',
  '🥣',
  '🧈',
  '🧀',
  '🥤',
  '🍦',
  '🍮',
  '🐄',
  '🌾',
  '🥚',
  '🍯',
];
const _units = ['L', 'ml', 'kg', 'g', 'pcs', 'pack'];

Future<void> showProductSheet(BuildContext context, {Product? product}) {
  final store = StoreScope.read(context);
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: product?.name);
  final price = TextEditingController(
    text: product == null ? '' : qty(product.price),
  );
  final stock = TextEditingController(
    text: product == null ? '0' : qty(product.stock),
  );
  final alert = TextEditingController(
    text: product == null ? '5' : qty(product.lowStockAlert),
  );
  String emoji = product?.emoji ?? '🥛';
  String unit = product?.unit ?? 'L';
  bool available = product?.available ?? true;
  bool isMilk = product?.isMilk ?? false;

  return showFormSheet(
    context,
    title: product == null ? 'Add product' : 'Edit product',
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in _emojis)
                  ChoiceChip(
                    label: Text(e, style: const TextStyle(fontSize: 20)),
                    selected: emoji == e,
                    showCheckmark: false,
                    onSelected: (_) => setS(() => emoji = e),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: name,
              validator: requiredField,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Product name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: price,
                    validator: positiveNumber,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      prefixText: '₹ ',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _units.contains(unit) ? unit : 'L',
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: [
                      for (final u in _units)
                        DropdownMenuItem(value: u, child: Text('per $u')),
                    ],
                    onChanged: (v) => unit = v ?? unit,
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('This is fresh milk'),
              subtitle: const Text('Stock comes from daily milk collection'),
              value: isMilk,
              onChanged: (v) => setS(() => isMilk = v),
            ),
            if (!isMilk)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: stock,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Stock',
                        suffixText: unit,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: alert,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Alert below',
                      ),
                    ),
                  ),
                ],
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visible to customers'),
              value: available,
              onChanged: (v) => setS(() => available = v),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final p = Product(
                  id: product?.id ?? store.newId(),
                  name: name.text.trim(),
                  unit: unit,
                  price: double.parse(price.text),
                  stock: double.tryParse(stock.text) ?? 0,
                  lowStockAlert: double.tryParse(alert.text) ?? 5,
                  emoji: emoji,
                  available: available,
                  isMilk: isMilk,
                );
                store.upsert(store.products, p, (x) => x.id == p.id);
                Navigator.pop(ctx);
              },
              child: Text(product == null ? 'Add product' : 'Save changes'),
            ),
            if (product != null)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.rose),
                onPressed: () async {
                  if (await confirm(
                    ctx,
                    'Delete ${product.name}?',
                    'Past sales are kept. Customers will no longer see this product.',
                  )) {
                    store.products.removeWhere((x) => x.id == product.id);
                    store.save();
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Delete product'),
              ),
          ],
        ),
      ),
    ),
  );
}
