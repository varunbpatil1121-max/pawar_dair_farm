import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/store.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'admin_shell.dart';
import 'sales_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _query = '';
  bool _duesOnly = false;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final list = store.customers
        .where(
          (c) =>
              _query.isEmpty ||
              c.name.toLowerCase().contains(_query) ||
              c.phone.contains(_query),
        )
        .where((c) => !_duesOnly || store.balanceOf(c.id) > 0)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => showCustomerSheet(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add customer'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          ResponsiveGrid(
            children: [
              StatCard(
                label: 'Total to collect',
                value: rupees(store.totalDues),
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.rose,
              ),
              StatCard(
                label: 'Daily milk booked',
                value:
                    '${qty(store.customers.where((c) => c.active).fold(0.0, (s, c) => s + c.dailyLiters))} L',
                icon: Icons.water_drop_outlined,
                color: AppColors.sky,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search name or phone',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              label: const Text('Only with dues'),
              selected: _duesOnly,
              onSelected: (v) => setState(() => _duesOnly = v),
            ),
          ),
          const SizedBox(height: 8),
          if (list.isEmpty)
            const EmptyState(
              icon: Icons.people_outline,
              title: 'No customers found',
            )
          else
            Card(
              child: Column(
                children: [
                  for (final c in list)
                    ListTile(
                      onTap: () =>
                          push(context, CustomerDetailScreen(customerId: c.id)),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.sky.withValues(alpha: 0.15),
                        child: Text(
                          c.name.isEmpty ? '?' : c.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.sky,
                          ),
                        ),
                      ),
                      title: Text(
                        c.name + (c.active ? '' : ' (inactive)'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${c.phone}${c.dailyLiters > 0 ? ' • ${qty(c.dailyLiters)} L/day' : ''}',
                      ),
                      trailing: _BalanceText(store.balanceOf(c.id)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BalanceText extends StatelessWidget {
  final double balance;
  const _BalanceText(this.balance);

  @override
  Widget build(BuildContext context) {
    final due = balance > 0.5;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          rupees(balance.abs()),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: due ? AppColors.rose : AppColors.green,
          ),
        ),
        Text(
          due ? 'due' : (balance < -0.5 ? 'advance' : 'clear'),
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}

class CustomerDetailScreen extends StatelessWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final c = store.userById(customerId);
    if (c == null) return Scaffold(appBar: AppBar());
    final balance = store.balanceOf(c.id);
    final now = DateTime.now();
    final thisMonth = store.spentInMonth(c.id, now);

    // Merge sales and payments into one ledger, newest first.
    final entries =
        <({DateTime date, String title, String sub, double amount, bool credit})>[
          for (final s in store.salesFor(c.id))
            (
              date: s.date,
              title: s.productName,
              sub:
                  '${qty(s.quantity)} ${s.unit} × ${rupees(s.rate)} • ${modeLabel(s.mode)}',
              amount: s.total,
              credit: false,
            ),
          for (final p in store.paymentsFor(c.id))
            (
              date: p.date,
              title: 'Payment received',
              sub:
                  '${modeLabel(p.mode)}${p.note.isEmpty ? '' : ' • ${p.note}'}',
              amount: p.amount,
              credit: true,
            ),
        ]..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showCustomerSheet(context, customer: c),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          HeroCard(
            colors: balance > 0.5 ? HeroCard.danger : AppColors.heroGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  balance > 0.5
                      ? 'Amount due'
                      : balance < -0.5
                      ? 'Advance paid'
                      : 'All settled',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  rupees(balance.abs()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${fmtMonth(now)}: ${rupees(thisMonth)} purchased',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.greenDark,
                        ),
                        onPressed: () => showPaymentSheet(context, c),
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Receive'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          minimumSize: const Size(0, 52),
                        ),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: buildBillText(store, c, now)),
                          );
                          toast(
                            context,
                            'Bill copied – paste it in WhatsApp/SMS',
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy bill'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SectionHeader('Details'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(c.phone),
                  subtitle: Text('Login password: ${c.password}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: c.phone));
                      toast(context, 'Phone copied');
                    },
                  ),
                ),
                if (c.address.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: Text(c.address),
                  ),
                ListTile(
                  leading: const Icon(Icons.water_drop_outlined),
                  title: Text(
                    c.dailyLiters > 0
                        ? '${qty(c.dailyLiters)} L daily • ${store.productById(c.subscriptionProductId)?.name ?? 'Milk'}'
                        : 'No daily subscription',
                  ),
                  subtitle: Text(
                    c.skips(now.add(const Duration(days: 1)))
                        ? 'Paused for tomorrow'
                        : 'Active',
                  ),
                ),
              ],
            ),
          ),
          SectionHeader(
            'Ledger',
            action: 'Add sale',
            onAction: () => showAddSaleSheet(context, customerId: c.id),
          ),
          if (entries.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No transactions yet.'),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final e in entries.take(60))
                    ListTile(
                      dense: true,
                      leading: Icon(
                        e.credit ? Icons.south_west : Icons.north_east,
                        color: e.credit ? AppColors.green : AppColors.rose,
                      ),
                      title: Text(
                        e.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${fmtShortDate(e.date)} • ${e.sub}'),
                      trailing: Text(
                        '${e.credit ? '+' : ''}${rupees(e.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: e.credit ? AppColors.green : null,
                        ),
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

String buildBillText(AppStore store, AppUser c, DateTime month) {
  final sales = store
      .salesFor(c.id)
      .where((s) => s.date.year == month.year && s.date.month == month.month)
      .toList();
  final byProduct = <String, ({double q, double amt, String unit})>{};
  for (final s in sales) {
    final cur = byProduct[s.productName];
    byProduct[s.productName] = (
      q: (cur?.q ?? 0) + s.quantity,
      amt: (cur?.amt ?? 0) + s.total,
      unit: s.unit,
    );
  }
  final b = StringBuffer()
    ..writeln('🐄 ${store.farmName}')
    ..writeln('Bill for ${fmtMonth(month)}')
    ..writeln('Customer: ${c.name}')
    ..writeln('----------------------');
  byProduct.forEach(
    (k, v) => b.writeln('$k: ${qty(v.q)} ${v.unit} = ${rupees(v.amt)}'),
  );
  b
    ..writeln('----------------------')
    ..writeln('Month total: ${rupees(store.spentInMonth(c.id, month))}')
    ..writeln('Total balance due: ${rupees(store.balanceOf(c.id))}');
  if (store.upiId.isNotEmpty) b.writeln('Pay via UPI: ${store.upiId}');
  b.writeln('Thank you! 🙏');
  return b.toString();
}

Future<void> showPaymentSheet(BuildContext context, AppUser c) {
  final store = StoreScope.read(context);
  final balance = store.balanceOf(c.id);
  final amount = TextEditingController(
    text: balance > 0 ? balance.round().toString() : '',
  );
  final note = TextEditingController();
  final formKey = GlobalKey<FormState>();
  PaymentMode mode = PaymentMode.cash;

  return showFormSheet(
    context,
    title: 'Receive payment – ${c.name}',
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Current due: ${rupees(balance)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amount,
              autofocus: true,
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
            SegmentedButton<PaymentMode>(
              segments: const [
                ButtonSegment(value: PaymentMode.cash, label: Text('Cash')),
                ButtonSegment(value: PaymentMode.upi, label: Text('UPI')),
              ],
              selected: {mode},
              onSelectionChanged: (s) => setS(() => mode = s.first),
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
                store.addPayment(
                  Payment(
                    id: store.newId(),
                    customerId: c.id,
                    amount: double.parse(amount.text),
                    date: DateTime.now(),
                    mode: mode,
                    note: note.text.trim(),
                  ),
                );
                Navigator.pop(ctx);
                toast(
                  context,
                  'Payment of ${rupees(double.parse(amount.text))} received',
                );
              },
              child: const Text('Save payment'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showCustomerSheet(BuildContext context, {AppUser? customer}) {
  final store = StoreScope.read(context);
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: customer?.name);
  final phone = TextEditingController(text: customer?.phone);
  final password = TextEditingController(text: customer?.password ?? '1234');
  final address = TextEditingController(text: customer?.address);
  final liters = TextEditingController(
    text: customer == null ? '1' : qty(customer.dailyLiters),
  );
  final milkProducts = store.products.where((p) => p.isMilk).toList();
  String? productId =
      customer?.subscriptionProductId ?? milkProducts.firstOrNull?.id;
  bool active = customer?.active ?? true;

  return showFormSheet(
    context,
    title: customer == null ? 'New customer' : 'Edit customer',
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
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone (used to log in)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                final p = (v ?? '').trim();
                if (p.length < 10) return 'Enter a 10-digit phone number';
                if (store.users.any(
                  (u) => u.phone == p && u.id != customer?.id,
                )) {
                  return 'This phone is already registered';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: password,
              validator: (v) =>
                  (v ?? '').length < 4 ? 'At least 4 characters' : null,
              decoration: const InputDecoration(
                labelText: 'Login password / PIN',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: address,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.home_outlined),
              ),
            ),
            const SectionHeader('Daily milk subscription'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: liters,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Liters per day',
                      suffixText: 'L',
                      helperText: '0 = no subscription',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (milkProducts.isNotEmpty)
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: productId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Milk type'),
                      items: [
                        for (final p in milkProducts)
                          DropdownMenuItem(value: p.id, child: Text(p.name)),
                      ],
                      onChanged: (v) => productId = v,
                    ),
                  ),
              ],
            ),
            if (customer != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Account active'),
                subtitle: const Text(
                  'Inactive customers cannot log in or get deliveries',
                ),
                value: active,
                onChanged: (v) => setS(() => active = v),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final u = AppUser(
                  id: customer?.id ?? store.newId(),
                  name: name.text.trim(),
                  phone: phone.text.trim(),
                  password: password.text,
                  role: UserRole.customer,
                  address: address.text.trim(),
                  dailyLiters: double.tryParse(liters.text) ?? 0,
                  subscriptionProductId: productId,
                  skipDates: customer?.skipDates,
                  active: active,
                  createdAt: customer?.createdAt,
                );
                store.upsert(store.users, u, (x) => x.id == u.id);
                Navigator.pop(ctx);
                if (customer == null) {
                  toast(
                    context,
                    'Account created. Login: ${u.phone} / ${u.password}',
                  );
                }
              },
              child: Text(customer == null ? 'Create account' : 'Save changes'),
            ),
          ],
        ),
      ),
    ),
  );
}
