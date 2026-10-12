import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'cattle_screen.dart';
import 'customers_screen.dart';
import 'dashboard_screen.dart';
import 'deliveries_screen.dart';
import 'expenses_screen.dart';
import 'milk_screen.dart';
import 'orders_screen.dart';
import 'products_screen.dart';
import 'reports_screen.dart';
import 'sales_screen.dart';
import 'vaccinations_screen.dart';
import '../feed/feed_screen.dart';
import '../feed/hygiene_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final pages = [
      DashboardScreen(onTab: (i) => setState(() => _tab = i)),
      const CattleScreen(),
      const MilkScreen(),
      const SalesScreen(),
      const MoreScreen(),
    ];
    final moreBadge = store.pendingOrderCount + store.vaccinationAlertCount;
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: FloatingNav(
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Cattle',
          ),
          const NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Milk',
          ),
          const NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Sales',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: moreBadge > 0,
              label: Text('$moreBadge'),
              child: const Icon(Icons.grid_view_outlined),
            ),
            selectedIcon: const Icon(Icons.grid_view_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

void push(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final items = [
      _MoreItem(
        'Farm Diary',
        '${store.posts.length} posts for customers',
        Icons.video_library_outlined,
        AppColors.rose,
        const FeedScreen(admin: true, showBack: true),
      ),
      _MoreItem(
        'Hygiene',
        '${store.hygieneOn(DateTime.now())?.score ?? 0}/${hygieneItems.length} done today',
        Icons.clean_hands_outlined,
        AppColors.teal,
        const HygieneScreen(editable: true),
      ),
      _MoreItem(
        'Customers',
        '${store.customers.length} accounts',
        Icons.people_alt_outlined,
        AppColors.sky,
        const CustomersScreen(),
      ),
      _MoreItem(
        'Today\'s Deliveries',
        '${store.subscribersFor(DateTime.now()).length} stops',
        Icons.delivery_dining_outlined,
        AppColors.teal,
        const DeliveriesScreen(),
      ),
      _MoreItem(
        'Orders',
        '${store.pendingOrderCount} pending',
        Icons.receipt_long_outlined,
        AppColors.amber,
        const OrdersScreen(),
        badge: store.pendingOrderCount,
      ),
      _MoreItem(
        'Products',
        '${store.products.length} items',
        Icons.inventory_2_outlined,
        AppColors.violet,
        const ProductsScreen(),
      ),
      _MoreItem(
        'Vaccinations',
        '${store.vaccinationAlertCount} due this week',
        Icons.vaccines_outlined,
        AppColors.rose,
        const VaccinationsScreen(),
        badge: store.vaccinationAlertCount,
      ),
      _MoreItem(
        'Expenses',
        'Feed, vet, labour…',
        Icons.account_balance_wallet_outlined,
        Colors.brown,
        const ExpensesScreen(),
      ),
      _MoreItem(
        'Reports',
        'Profit & trends',
        Icons.insights_outlined,
        AppColors.green,
        const ReportsScreen(),
      ),
      _MoreItem(
        'Settings',
        'Farm profile & data',
        Icons.settings_outlined,
        Colors.blueGrey,
        const SettingsScreen(),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          HeroCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text('🐄', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.farmName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${store.cows.length} cattle • ${store.customers.length} customers',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => push(context, const SettingsScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ResponsiveGrid(
            children: [
              for (final it in items)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => push(context, it.page),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Badge(
                            isLabelVisible: it.badge > 0,
                            label: Text('${it.badge}'),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: it.color.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(it.icon, color: it.color),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            it.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            it.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => store.logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
          ),
        ],
      ),
    );
  }
}

class _MoreItem {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final Widget page;
  final int badge;
  _MoreItem(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.page, {
    this.badge = 0,
  });
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AppStore store = StoreScope.read(context);
  late final _farm = TextEditingController(text: store.farmName);
  late final _upi = TextEditingController(text: store.upiId);
  final _oldPw = TextEditingController();
  final _newPw = TextEditingController();

  @override
  void dispose() {
    _farm.dispose();
    _upi.dispose();
    _oldPw.dispose();
    _newPw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = store.currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader('Farm profile'),
          TextField(
            controller: _farm,
            decoration: const InputDecoration(
              labelText: 'Farm name',
              prefixIcon: Icon(Icons.home_work_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _upi,
            decoration: const InputDecoration(
              labelText: 'UPI ID (shown to customers for payment)',
              prefixIcon: Icon(Icons.qr_code_2),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              store.farmName = _farm.text.trim().isEmpty
                  ? store.farmName
                  : _farm.text.trim();
              store.upiId = _upi.text.trim();
              store.save();
              toast(context, 'Farm profile saved');
            },
            child: const Text('Save profile'),
          ),
          const SectionHeader('Change admin password'),
          TextField(
            controller: _oldPw,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPw,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New password (min 4 chars)',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            onPressed: () {
              if (_oldPw.text != admin.password) {
                toast(context, 'Current password is wrong');
                return;
              }
              if (_newPw.text.length < 4) {
                toast(context, 'New password is too short');
                return;
              }
              admin.password = _newPw.text;
              store.save();
              _oldPw.clear();
              _newPw.clear();
              toast(context, 'Password changed');
            },
            child: const Text('Update password'),
          ),
          const SectionHeader('Data'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.restart_alt),
                  title: const Text('Load demo data'),
                  subtitle: const Text('Replace everything with sample data'),
                  onTap: () async {
                    if (await confirm(
                      context,
                      'Load demo data?',
                      'All current records will be replaced with sample data.',
                      action: 'Load',
                    )) {
                      store.seedDemoData();
                      store.login('9999999999', 'admin123');
                      if (context.mounted) toast(context, 'Demo data loaded');
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever,
                    color: AppColors.rose,
                  ),
                  title: const Text(
                    'Start fresh',
                    style: TextStyle(color: AppColors.rose),
                  ),
                  subtitle: const Text(
                    'Delete all cattle, sales, customers & records. Products and your admin login are kept.',
                  ),
                  onTap: () async {
                    if (await confirm(
                      context,
                      'Delete all data?',
                      'This cannot be undone.',
                      action: 'Delete all',
                    )) {
                      store.clearAll();
                      if (context.mounted) {
                        toast(context, 'All records cleared');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
