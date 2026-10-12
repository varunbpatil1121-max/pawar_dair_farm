import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/store.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../admin/orders_screen.dart';
import '../admin/sales_screen.dart' show modeLabel;
import '../../widgets/media_view.dart';
import '../feed/feed_screen.dart';
import 'shop_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final me = store.currentUser!;
    final activeOrders = store
        .ordersFor(me.id)
        .where(
          (o) =>
              o.status == OrderStatus.pending ||
              o.status == OrderStatus.accepted,
        )
        .length;
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          CustomerHome(onTab: (i) => setState(() => _tab = i)),
          const FeedScreen(admin: false),
          ShopScreen(onOrdered: () => setState(() => _tab = 3)),
          const MyOrdersScreen(),
          const BillsScreen(),
        ],
      ),
      bottomNavigationBar: FloatingNav(
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library),
            label: 'Farm',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: activeOrders > 0,
              label: Text('$activeOrders'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: const Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Bills',
          ),
        ],
      ),
    );
  }
}

class CustomerHome extends StatelessWidget {
  final ValueChanged<int> onTab;
  const CustomerHome({super.key, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final me = store.currentUser!;
    final now = DateTime.now();
    final today = dateOnly(now);
    final tomorrow = today.add(const Duration(days: 1));
    final balance = store.balanceOf(me.id);
    final product =
        store.productById(me.subscriptionProductId) ?? store.milkProduct;
    final monthSales = store
        .salesFor(me.id)
        .where((s) => s.date.year == now.year && s.date.month == now.month)
        .toList();
    final monthMilk = monthSales
        .where((s) => s.orderId?.startsWith('sub-') ?? false)
        .fold(0.0, (s, x) => s + x.quantity);
    final deliveredToday = store.deliveredTo(me.id, today);
    final hasSub = me.dailyLiters > 0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${greeting()},',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${me.name} 👋',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: store.logout,
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Balance card
            HeroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        balance > 0.5
                            ? 'Amount to pay'
                            : balance < -0.5
                            ? 'Advance balance'
                            : 'All paid up ✓',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const Spacer(),
                      const Text('🐄', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                  Text(
                    rupees(balance.abs()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${store.farmName} • ${fmtMonth(now)}: ${rupees(store.spentInMonth(me.id, now))}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (store.upiId.isNotEmpty && balance > 0.5) ...[
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.greenDark,
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: store.upiId));
                        toast(context, 'UPI ID copied: ${store.upiId}');
                      },
                      icon: const Icon(Icons.qr_code_2),
                      label: Text('Pay via UPI • ${store.upiId}'),
                    ),
                  ],
                ],
              ),
            ),

            // Transparency
            const SizedBox(height: 14),
            const TrustCard(admin: false),
            if (store.posts.isNotEmpty) ...[
              SectionHeader(
                'From the farm',
                action: 'See all',
                onAction: () => onTab(1),
              ),
              SizedBox(
                height: 212,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: store.feed.take(6).length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) =>
                      _PostPreview(post: store.feed[i], onTap: () => onTab(1)),
                ),
              ),
            ],

            // Subscription
            const SectionHeader('My daily milk'),
            if (!hasSub)
              Card(
                child: ListTile(
                  leading: const Text('🥛', style: TextStyle(fontSize: 28)),
                  title: const Text('No daily subscription'),
                  subtitle: const Text(
                    'Ask the farm to start daily delivery, or order from the shop.',
                  ),
                  trailing: TextButton(
                    onPressed: () => onTab(2),
                    child: const Text('Shop'),
                  ),
                ),
              )
            else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            product?.emoji ?? '🥛',
                            style: const TextStyle(fontSize: 34),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${qty(me.dailyLiters)} L ${product?.name ?? 'Milk'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  '${rupees((product?.price ?? 0) * me.dailyLiters)} per day',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Pill(
                            me.skips(today)
                                ? 'Paused today'
                                : deliveredToday
                                ? 'Delivered today ✓'
                                : 'On the way',
                            color: me.skips(today)
                                ? AppColors.amber
                                : deliveredToday
                                ? AppColors.green
                                : AppColors.sky,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tap a day to pause or resume delivery',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (var i = 1; i <= 7; i++)
                            Expanded(
                              child: _DayToggle(
                                me: me,
                                day: today.add(Duration(days: i)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: () {
                            store.toggleSkip(me, tomorrow);
                            toast(
                              context,
                              me.skips(tomorrow)
                                  ? 'Tomorrow\'s milk paused'
                                  : 'Tomorrow\'s milk resumed',
                            );
                          },
                          icon: Icon(
                            me.skips(tomorrow) ? Icons.play_arrow : Icons.pause,
                          ),
                          label: Text(
                            me.skips(tomorrow)
                                ? 'Resume tomorrow\'s milk'
                                : 'Pause tomorrow\'s milk',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            ResponsiveGrid(
              children: [
                StatCard(
                  label: 'Milk this month',
                  value: '${qty(monthMilk)} L',
                  icon: Icons.water_drop,
                  color: AppColors.sky,
                ),
                StatCard(
                  label: 'Orders',
                  value: '${store.ordersFor(me.id).length}',
                  icon: Icons.receipt_long,
                  color: AppColors.amber,
                  onTap: () => onTab(3),
                ),
              ],
            ),

            // Featured products
            SectionHeader(
              'Fresh from the farm',
              action: 'See all',
              onAction: () => onTab(2),
            ),
            SizedBox(
              height: 128,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in store.products.where((p) => p.available))
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: SizedBox(
                        width: 120,
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => onTab(2),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.emoji,
                                    style: const TextStyle(fontSize: 30),
                                  ),
                                  const Spacer(),
                                  Text(
                                    p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${rupees(p.price)}/${p.unit}',
                                    style: const TextStyle(
                                      color: AppColors.green,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Recent
            if (monthSales.isNotEmpty) ...[
              SectionHeader(
                'Recent deliveries',
                action: 'Bill',
                onAction: () => onTab(4),
              ),
              Card(
                child: Column(
                  children: [
                    for (final s in monthSales.take(5))
                      ListTile(
                        dense: true,
                        leading: Text(
                          store.productById(s.productId)?.emoji ?? '🥛',
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(
                          '${s.productName} • ${qty(s.quantity)} ${s.unit}',
                        ),
                        subtitle: Text(fmtDay(s.date)),
                        trailing: Text(
                          rupees(s.total),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayToggle extends StatelessWidget {
  final AppUser me;
  final DateTime day;
  const _DayToggle({required this.me, required this.day});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final paused = me.skips(day);
    final color = paused ? AppColors.amber : AppColors.green;
    return GestureDetector(
      onTap: () => store.toggleSkip(me, day),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: paused ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Text(
              const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1],
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${day.day}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Icon(paused ? Icons.pause : Icons.check, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final orders = store.ordersFor(store.currentUser!.id);
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: orders.isEmpty
          ? const EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'No orders yet',
              message: 'Order ghee, paneer, curd and more from the Shop tab',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => OrderCard(order: orders[i], admin: false),
            ),
    );
  }
}

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final me = store.currentUser!;
    final next = DateTime(_month.year, _month.month + 1);
    final sales = store
        .salesFor(me.id)
        .where((s) => !s.date.isBefore(_month) && s.date.isBefore(next))
        .toList();
    final payments = store
        .paymentsFor(me.id)
        .where((p) => !p.date.isBefore(_month) && p.date.isBefore(next))
        .toList();
    final byProduct =
        <String, ({double q, double amt, String unit, String emoji})>{};
    for (final s in sales) {
      final cur = byProduct[s.productName];
      byProduct[s.productName] = (
        q: (cur?.q ?? 0) + s.quantity,
        amt: (cur?.amt ?? 0) + s.total,
        unit: s.unit,
        emoji: store.productById(s.productId)?.emoji ?? '🛒',
      );
    }
    final total = sales.fold(0.0, (s, x) => s + x.total);
    final paid = payments.fold(0.0, (s, x) => s + x.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Bills & payments')),
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
          ResponsiveGrid(
            children: [
              StatCard(
                label: 'Month bill',
                value: rupees(total),
                icon: Icons.receipt,
                color: AppColors.amber,
              ),
              StatCard(
                label: 'Paid this month',
                value: rupees(paid),
                icon: Icons.check_circle_outline,
                color: AppColors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Total outstanding'),
              trailing: Text(
                rupees(store.balanceOf(me.id)),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SectionHeader('Bill summary'),
          if (byProduct.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No purchases this month.'),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final e in byProduct.entries)
                    ListTile(
                      leading: Text(
                        e.value.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(e.key),
                      subtitle: Text('${qty(e.value.q)} ${e.value.unit}'),
                      trailing: Text(
                        rupees(e.value.amt),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
            ),
          if (payments.isNotEmpty) ...[
            const SectionHeader('Payments'),
            Card(
              child: Column(
                children: [
                  for (final p in payments)
                    ListTile(
                      leading: const Icon(
                        Icons.south_west,
                        color: AppColors.green,
                      ),
                      title: Text(
                        rupees(p.amount),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${fmtDate(p.date)} • ${modeLabel(p.mode)}',
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (sales.isNotEmpty) ...[
            const SectionHeader('Daily entries'),
            Card(
              child: Column(
                children: [
                  for (final s in sales)
                    ListTile(
                      dense: true,
                      title: Text(
                        '${s.productName} • ${qty(s.quantity)} ${s.unit}',
                      ),
                      subtitle: Text(fmtDay(s.date)),
                      trailing: Text(rupees(s.total)),
                    ),
                ],
              ),
            ),
          ],
          const SectionHeader('Account'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(me.phone),
                ),
                if (me.address.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: Text(me.address),
                  ),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _changePassword(context, store, me),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.rose),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: AppColors.rose),
                  ),
                  onTap: store.logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _changePassword(BuildContext context, AppStore store, AppUser me) {
    final oldPw = TextEditingController();
    final newPw = TextEditingController();
    showFormSheet(
      context,
      title: 'Change password',
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: oldPw,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newPw,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New password (min 4)',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              if (oldPw.text != me.password) {
                toast(context, 'Current password is wrong');
                return;
              }
              if (newPw.text.length < 4) {
                toast(context, 'New password is too short');
                return;
              }
              me.password = newPw.text;
              store.save();
              Navigator.pop(ctx);
              toast(context, 'Password changed');
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _PostPreview extends StatelessWidget {
  final FarmPost post;
  final VoidCallback onTap;
  const _PostPreview({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cat = categoryOf(post.category);
    return SizedBox(
      width: 190,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  IgnorePointer(
                    child: PostMedia(
                      post: post,
                      aspectRatio: 16 / 11,
                      interactive: false,
                    ),
                  ),
                  if (post.mediaType == MediaType.video)
                    const Positioned.fill(
                      child: Center(
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Text(
                  '${cat.emoji} ${cat.label} • ${timeAgo(post.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
