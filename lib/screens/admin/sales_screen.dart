import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

String modeLabel(PaymentMode m) => switch (m) {
  PaymentMode.cash => 'Cash',
  PaymentMode.upi => 'UPI',
  PaymentMode.credit => 'Credit',
};

Color modeColor(PaymentMode m) => switch (m) {
  PaymentMode.cash => AppColors.green,
  PaymentMode.upi => AppColors.violet,
  PaymentMode.credit => AppColors.amber,
};

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  DateTime _day = dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final list = store.salesOn(_day);
    final total = list.fold(0.0, (s, x) => s + x.total);
    final byMode = {
      for (final m in PaymentMode.values)
        m: list.where((s) => s.mode == m).fold(0.0, (s, x) => s + x.total),
    };
    final liters = store.litersSoldOn(_day);
    final isToday = sameDay(_day, DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Sales')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => showAddSaleSheet(context, day: _day),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('New sale'),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        isToday
                            ? 'Today • ${fmtShortDate(_day)}'
                            : fmtDay(_day),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
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
          ResponsiveGrid(
            children: [
              StatCard(
                label: 'Total sales',
                value: rupees(total),
                icon: Icons.currency_rupee,
                color: AppColors.green,
              ),
              StatCard(
                label: 'Milk sold',
                value: '${qty(liters)} L',
                icon: Icons.water_drop,
                color: AppColors.sky,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  for (final m in PaymentMode.values)
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            modeLabel(m),
                            style: TextStyle(
                              color: modeColor(m),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            child: Text(
                              rupees(byMode[m]!),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
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
          SectionHeader('${list.length} transactions'),
          if (list.isEmpty)
            const EmptyState(
              icon: Icons.receipt_outlined,
              title: 'No sales on this day',
            )
          else
            Card(
              child: Column(
                children: [
                  for (final s in list)
                    Dismissible(
                      key: ValueKey(s.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: AppColors.rose,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) => confirm(
                        context,
                        'Delete sale?',
                        'Stock will be restored.',
                      ),
                      onDismissed: (_) => store.deleteSale(s.id),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: modeColor(
                            s.mode,
                          ).withValues(alpha: 0.15),
                          child: Text(
                            store.productById(s.productId)?.emoji ?? '🥛',
                          ),
                        ),
                        title: Text(
                          '${s.customerName} • ${s.productName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${qty(s.quantity)} ${s.unit} × ${rupees(s.rate)} • ${fmtTime(s.date)}${s.orderId?.startsWith('sub-') == true ? ' • Daily' : ''}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              rupees(s.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              modeLabel(s.mode),
                              style: TextStyle(
                                color: modeColor(s.mode),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (list.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Swipe left on a sale to delete it',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> showAddSaleSheet(
  BuildContext context, {
  DateTime? day,
  String? customerId,
}) {
  final store = StoreScope.read(context);
  final products = store.products.where((p) => p.available).toList();
  if (products.isEmpty) {
    toast(context, 'Add a product first');
    return Future.value();
  }
  final formKey = GlobalKey<FormState>();
  final qtyCtl = TextEditingController(text: '1');
  Product product = products.first;
  final rateCtl = TextEditingController(text: qty(product.price));
  String? custId = customerId;
  PaymentMode mode = customerId == null ? PaymentMode.cash : PaymentMode.credit;
  final saleDay = day ?? DateTime.now();

  return showFormSheet(
    context,
    title: 'New sale',
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        final q = double.tryParse(qtyCtl.text) ?? 0;
        final r = double.tryParse(rateCtl.text) ?? 0;
        return Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Product', style: Theme.of(ctx).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in products)
                    ChoiceChip(
                      avatar: Text(p.emoji),
                      label: Text(p.name),
                      selected: product.id == p.id,
                      onSelected: (_) => setS(() {
                        product = p;
                        rateCtl.text = qty(p.price);
                      }),
                    ),
                ],
              ),
              if (!product.isMilk)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'In stock: ${qty(product.stock)} ${product.unit}',
                    style: TextStyle(
                      color: product.isLowStock
                          ? AppColors.rose
                          : AppColors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Milk in can today: ${qty(store.milkAvailableToday())} L',
                    style: const TextStyle(
                      color: AppColors.sky,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: qtyCtl,
                      validator: positiveNumber,
                      onChanged: (_) => setS(() {}),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        suffixText: product.unit,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: rateCtl,
                      validator: positiveNumber,
                      onChanged: (_) => setS(() {}),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Rate',
                        prefixText: '₹ ',
                        suffixText: '/${product.unit}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final n in [0.5, 1, 2, 5, 10])
                    ActionChip(
                      label: Text('${qty(n)} ${product.unit}'),
                      onPressed: () => setS(() => qtyCtl.text = qty(n)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: custId,
                decoration: const InputDecoration(
                  labelText: 'Customer',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Walk-in customer'),
                  ),
                  for (final c in store.customers)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setS(() {
                  custId = v;
                  if (v == null && mode == PaymentMode.credit) {
                    mode = PaymentMode.cash;
                  }
                }),
              ),
              const SizedBox(height: 16),
              SegmentedButton<PaymentMode>(
                segments: [
                  const ButtonSegment(
                    value: PaymentMode.cash,
                    label: Text('Cash'),
                    icon: Icon(Icons.payments_outlined),
                  ),
                  const ButtonSegment(
                    value: PaymentMode.upi,
                    label: Text('UPI'),
                    icon: Icon(Icons.qr_code),
                  ),
                  ButtonSegment(
                    value: PaymentMode.credit,
                    label: const Text('Credit'),
                    icon: const Icon(Icons.book_outlined),
                    enabled: custId != null,
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (s) => setS(() => mode = s.first),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 16)),
                    const Spacer(),
                    Text(
                      rupees(q * r),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  final cust = custId == null ? null : store.userById(custId!);
                  final now = DateTime.now();
                  store.addSale(
                    Sale(
                      id: store.newId(),
                      customerId: cust?.id,
                      customerName: cust?.name ?? 'Walk-in',
                      productId: product.id,
                      productName: product.name,
                      unit: product.unit,
                      quantity: q,
                      rate: r,
                      date: DateTime(
                        saleDay.year,
                        saleDay.month,
                        saleDay.day,
                        now.hour,
                        now.minute,
                      ),
                      mode: mode,
                    ),
                  );
                  Navigator.pop(ctx);
                  toast(context, 'Sale of ${rupees(q * r)} recorded');
                },
                child: const Text('Record sale'),
              ),
            ],
          ),
        );
      },
    ),
  );
}
