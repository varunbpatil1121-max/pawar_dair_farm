import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/media.dart';

/// Single source of truth for the app. Holds every collection in memory,
/// persists to local storage on each change, and exposes the business logic
/// (dues, stock, deliveries, reports) the screens need.
class AppStore extends ChangeNotifier {
  static const _key = 'pawar_dairy_v1';
  static const _sessionKey = 'pawar_dairy_session';

  late SharedPreferences _prefs;

  List<AppUser> users = [];
  List<Cow> cows = [];
  List<MilkRecord> milk = [];
  List<Vaccination> vaccinations = [];
  List<Product> products = [];
  List<Sale> sales = [];
  List<Order> orders = [];
  List<Payment> payments = [];
  List<Expense> expenses = [];
  List<FarmPost> posts = [];
  List<HygieneLog> hygiene = [];

  String farmName = 'Pawar Dairy Farm';
  String upiId = '';
  AppUser? currentUser;

  int _seq = 0;
  String newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${(_seq++).toRadixString(36)}';

  // ---------------------------------------------------------------- storage

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_key);
    if (raw == null) {
      seedDemoData();
    } else {
      try {
        _fromJson(jsonDecode(raw));
      } catch (_) {
        seedDemoData();
      }
    }
    final sid = _prefs.getString(_sessionKey);
    if (sid != null) currentUser = userById(sid);
  }

  void _fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String k, T Function(Map<String, dynamic>) f) =>
        ((j[k] ?? []) as List)
            .map((e) => f(Map<String, dynamic>.from(e)))
            .toList();
    users = list('users', AppUser.fromJson);
    cows = list('cows', Cow.fromJson);
    milk = list('milk', MilkRecord.fromJson);
    vaccinations = list('vaccinations', Vaccination.fromJson);
    products = list('products', Product.fromJson);
    sales = list('sales', Sale.fromJson);
    orders = list('orders', Order.fromJson);
    payments = list('payments', Payment.fromJson);
    expenses = list('expenses', Expense.fromJson);
    posts = list('posts', FarmPost.fromJson);
    hygiene = list('hygiene', HygieneLog.fromJson);
    farmName = j['farmName'] ?? farmName;
    upiId = j['upiId'] ?? '';
  }

  Map<String, dynamic> _toJson() => {
    'users': users.map((e) => e.toJson()).toList(),
    'cows': cows.map((e) => e.toJson()).toList(),
    'milk': milk.map((e) => e.toJson()).toList(),
    'vaccinations': vaccinations.map((e) => e.toJson()).toList(),
    'products': products.map((e) => e.toJson()).toList(),
    'sales': sales.map((e) => e.toJson()).toList(),
    'orders': orders.map((e) => e.toJson()).toList(),
    'payments': payments.map((e) => e.toJson()).toList(),
    'expenses': expenses.map((e) => e.toJson()).toList(),
    'posts': posts.map((e) => e.toJson()).toList(),
    'hygiene': hygiene.map((e) => e.toJson()).toList(),
    'farmName': farmName,
    'upiId': upiId,
  };

  /// Persist and refresh listeners. Call after every mutation.
  void save() {
    _prefs.setString(_key, jsonEncode(_toJson()));
    notifyListeners();
  }

  // ------------------------------------------------------------------- auth

  String? login(String phone, String password) {
    final u = users.where((u) => u.phone == phone.trim()).firstOrNull;
    if (u == null) return 'No account found with this phone number';
    if (u.password != password) return 'Wrong password';
    if (!u.active) return 'This account is disabled. Contact the farm.';
    currentUser = u;
    _prefs.setString(_sessionKey, u.id);
    notifyListeners();
    return null;
  }

  void logout() {
    currentUser = null;
    _prefs.remove(_sessionKey);
    notifyListeners();
  }

  // ---------------------------------------------------------------- lookups

  AppUser? userById(String id) => users.where((u) => u.id == id).firstOrNull;
  Cow? cowById(String id) => cows.where((c) => c.id == id).firstOrNull;
  Product? productById(String? id) =>
      products.where((p) => p.id == id).firstOrNull;

  List<AppUser> get customers =>
      users.where((u) => u.role == UserRole.customer).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  Product? get milkProduct => products.where((p) => p.isMilk).firstOrNull;

  // ------------------------------------------------------------------- milk

  double litersCollectedOn(DateTime day, {Shift? shift}) => milk
      .where((m) => sameDay(m.date, day) && (shift == null || m.shift == shift))
      .fold(0.0, (s, m) => s + m.liters);

  double litersSoldOn(DateTime day) => sales
      .where(
        (s) =>
            sameDay(s.date, day) && (productById(s.productId)?.isMilk ?? false),
      )
      .fold(0.0, (s, x) => s + x.quantity);

  /// Milk still in the can today = collected − sold.
  double milkAvailableToday() {
    final now = DateTime.now();
    return max(0, litersCollectedOn(now) - litersSoldOn(now));
  }

  double cowAverage(String cowId, {int days = 7}) {
    final from = dateOnly(DateTime.now()).subtract(Duration(days: days - 1));
    final total = milk
        .where((m) => m.cowId == cowId && !m.date.isBefore(from))
        .fold(0.0, (s, m) => s + m.liters);
    return total / days;
  }

  List<MilkRecord> milkFor({String? cowId, DateTime? day}) =>
      milk
          .where(
            (m) =>
                (cowId == null || m.cowId == cowId) &&
                (day == null || sameDay(m.date, day)),
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  void addMilk(MilkRecord r) {
    // One entry per cow per shift per day: replace if it exists.
    milk.removeWhere(
      (m) =>
          m.cowId == r.cowId && m.shift == r.shift && sameDay(m.date, r.date),
    );
    milk.add(r);
    save();
  }

  void deleteMilk(String id) {
    milk.removeWhere((m) => m.id == id);
    save();
  }

  // ------------------------------------------------------------------ sales

  double revenueOn(DateTime day) =>
      sales.where((s) => sameDay(s.date, day)).fold(0.0, (s, x) => s + x.total);

  double revenueBetween(DateTime from, DateTime to) => sales
      .where((s) => !s.date.isBefore(from) && s.date.isBefore(to))
      .fold(0.0, (s, x) => s + x.total);

  double expensesBetween(DateTime from, DateTime to) => expenses
      .where((e) => !e.date.isBefore(from) && e.date.isBefore(to))
      .fold(0.0, (s, x) => s + x.amount);

  double litersCollectedBetween(DateTime from, DateTime to) => milk
      .where((m) => !m.date.isBefore(from) && m.date.isBefore(to))
      .fold(0.0, (s, x) => s + x.liters);

  List<Sale> salesOn(DateTime day) =>
      sales.where((s) => sameDay(s.date, day)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  void addSale(Sale s) {
    sales.add(s);
    final p = productById(s.productId);
    if (p != null && !p.isMilk) p.stock = max(0, p.stock - s.quantity);
    save();
  }

  void deleteSale(String id) {
    final s = sales.where((x) => x.id == id).firstOrNull;
    if (s == null) return;
    final p = productById(s.productId);
    if (p != null && !p.isMilk) p.stock += s.quantity;
    sales.remove(s);
    save();
  }

  // ------------------------------------------------------- customer ledger

  List<Sale> salesFor(String customerId) =>
      sales.where((s) => s.customerId == customerId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<Payment> paymentsFor(String customerId) =>
      payments.where((p) => p.customerId == customerId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  /// Amount the customer owes. Credit purchases add to it; payments reduce it.
  double balanceOf(String customerId) {
    final credit = sales
        .where(
          (s) => s.customerId == customerId && s.mode == PaymentMode.credit,
        )
        .fold(0.0, (s, x) => s + x.total);
    final paid = payments
        .where((p) => p.customerId == customerId)
        .fold(0.0, (s, x) => s + x.amount);
    return credit - paid;
  }

  double get totalDues =>
      customers.fold(0.0, (s, c) => s + max(0, balanceOf(c.id)));

  double spentInMonth(String customerId, DateTime month) => sales
      .where(
        (s) =>
            s.customerId == customerId &&
            s.date.year == month.year &&
            s.date.month == month.month,
      )
      .fold(0.0, (s, x) => s + x.total);

  void addPayment(Payment p) {
    payments.add(p);
    save();
  }

  // ------------------------------------------------- daily milk deliveries

  String _subRef(DateTime day) =>
      'sub-${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';

  List<AppUser> subscribersFor(DateTime day) => customers
      .where((c) => c.active && c.dailyLiters > 0 && !c.skips(day))
      .toList();

  bool deliveredTo(String customerId, DateTime day) =>
      sales.any((s) => s.customerId == customerId && s.orderId == _subRef(day));

  void markDelivered(AppUser c, DateTime day, {double? liters}) {
    if (deliveredTo(c.id, day)) return;
    final p = productById(c.subscriptionProductId) ?? milkProduct;
    if (p == null) return;
    final now = DateTime.now();
    addSale(
      Sale(
        id: newId(),
        customerId: c.id,
        customerName: c.name,
        productId: p.id,
        productName: p.name,
        unit: p.unit,
        quantity: liters ?? c.dailyLiters,
        rate: p.price,
        date: DateTime(day.year, day.month, day.day, now.hour, now.minute),
        mode: PaymentMode.credit,
        orderId: _subRef(day),
      ),
    );
  }

  void undoDelivery(String customerId, DateTime day) {
    final s = sales
        .where((s) => s.customerId == customerId && s.orderId == _subRef(day))
        .firstOrNull;
    if (s != null) deleteSale(s.id);
  }

  void toggleSkip(AppUser c, DateTime day) {
    if (c.skips(day)) {
      c.skipDates.removeWhere((d) => sameDay(d, day));
    } else {
      c.skipDates.add(dateOnly(day));
    }
    save();
  }

  // ----------------------------------------------------------------- orders

  List<Order> ordersFor(String customerId) =>
      orders.where((o) => o.customerId == customerId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int get pendingOrderCount =>
      orders.where((o) => o.status == OrderStatus.pending).length;

  void placeOrder(Order o) {
    orders.add(o);
    save();
  }

  void setOrderStatus(Order o, OrderStatus status) {
    if (o.status == status) return;
    // Delivering an order books it on the customer's credit ledger.
    if (status == OrderStatus.delivered) {
      for (final i in o.items) {
        addSale(
          Sale(
            id: newId(),
            customerId: o.customerId,
            customerName: o.customerName,
            productId: i.productId,
            productName: i.productName,
            unit: i.unit,
            quantity: i.quantity,
            rate: i.rate,
            date: DateTime.now(),
            mode: PaymentMode.credit,
            orderId: o.id,
          ),
        );
      }
    }
    o.status = status;
    save();
  }

  // ------------------------------------------------------- cows & health

  List<Vaccination> vaccinationsFor(String cowId) =>
      vaccinations.where((v) => v.cowId == cowId).toList()
        ..sort((a, b) => b.dueDate.compareTo(a.dueDate));

  /// Pending vaccinations, overdue first, then by due date.
  List<Vaccination> get upcomingVaccinations =>
      vaccinations.where((v) => !v.isDone && cowById(v.cowId) != null).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  int get vaccinationAlertCount =>
      upcomingVaccinations.where((v) => v.daysUntilDue <= 7).length;

  void deleteCow(String id) {
    cows.removeWhere((c) => c.id == id);
    milk.removeWhere((m) => m.cowId == id);
    vaccinations.removeWhere((v) => v.cowId == id);
    save();
  }

  // -------------------------------------------------------------- farm feed

  /// Pinned first, then newest.
  List<FarmPost> get feed => [...posts]
    ..sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });

  void toggleLike(FarmPost p, String userId) {
    p.likes.contains(userId) ? p.likes.remove(userId) : p.likes.add(userId);
    save();
  }

  void deletePost(FarmPost p) {
    if (p.mediaPath != null) deleteMediaFile(p.mediaPath!);
    posts.removeWhere((x) => x.id == p.id);
    save();
  }

  // ---------------------------------------------------------------- hygiene

  HygieneLog? hygieneOn(DateTime day) =>
      hygiene.where((h) => sameDay(h.date, day)).firstOrNull;

  /// Today's log, created on first access.
  HygieneLog hygieneToday() {
    final existing = hygieneOn(DateTime.now());
    if (existing != null) return existing;
    final log = HygieneLog(date: dateOnly(DateTime.now()));
    hygiene.add(log);
    return log;
  }

  void toggleHygiene(String key) {
    final log = hygieneToday();
    log.done.contains(key) ? log.done.remove(key) : log.done.add(key);
    save();
  }

  /// Consecutive fully-completed days, counting back from today (or
  /// yesterday if today isn't finished yet).
  int get hygieneStreak {
    var day = dateOnly(DateTime.now());
    if (!(hygieneOn(day)?.complete ?? false)) {
      day = day.subtract(const Duration(days: 1));
    }
    var n = 0;
    while (hygieneOn(day)?.complete ?? false) {
      n++;
      day = day.subtract(const Duration(days: 1));
    }
    return n;
  }

  /// Average fat % across all cows over the last [days] days.
  double? averageFat({int days = 7}) {
    final from = dateOnly(DateTime.now()).subtract(Duration(days: days - 1));
    final fats = milk
        .where((m) => m.fat != null && !m.date.isBefore(from))
        .map((m) => m.fat!)
        .toList();
    if (fats.isEmpty) return null;
    return fats.reduce((a, b) => a + b) / fats.length;
  }

  // --------------------------------------------------------------- generic

  void upsert<T>(List<T> list, T item, bool Function(T) match) {
    final i = list.indexWhere(match);
    if (i >= 0) {
      list[i] = item;
    } else {
      list.add(item);
    }
    save();
  }

  // ------------------------------------------------------------- demo data

  void clearAll() {
    final admin = users.firstWhere((u) => u.isAdmin);
    users = [admin];
    cows = [];
    milk = [];
    vaccinations = [];
    sales = [];
    orders = [];
    payments = [];
    expenses = [];
    for (final p in posts) {
      if (p.mediaPath != null) deleteMediaFile(p.mediaPath!);
    }
    posts = [];
    hygiene = [];
    save();
  }

  void seedDemoData() {
    final rnd = Random(7);
    final today = dateOnly(DateTime.now());

    users = [
      AppUser(
        id: 'admin',
        name: 'Pawar',
        phone: '9999999999',
        password: 'admin123',
        role: UserRole.admin,
      ),
      AppUser(
        id: 'c1',
        name: 'Ramesh Patil',
        phone: '9876543210',
        password: '1234',
        role: UserRole.customer,
        address: 'Shivaji Nagar, House 12',
        dailyLiters: 2,
        subscriptionProductId: 'p1',
      ),
      AppUser(
        id: 'c2',
        name: 'Sunita Jadhav',
        phone: '9876500001',
        password: '1234',
        role: UserRole.customer,
        address: 'Ganesh Colony, Lane 3',
        dailyLiters: 1,
        subscriptionProductId: 'p1',
      ),
      AppUser(
        id: 'c3',
        name: 'Hotel Sai Krupa',
        phone: '9876500002',
        password: '1234',
        role: UserRole.customer,
        address: 'Main Market Road',
        dailyLiters: 10,
        subscriptionProductId: 'p1',
      ),
      AppUser(
        id: 'c4',
        name: 'Anil Shinde',
        phone: '9876500003',
        password: '1234',
        role: UserRole.customer,
        address: 'Station Road',
        dailyLiters: 1.5,
        subscriptionProductId: 'p2',
      ),
    ];

    products = [
      Product(
        id: 'p1',
        name: 'Cow Milk',
        unit: 'L',
        price: 60,
        emoji: '🥛',
        isMilk: true,
      ),
      Product(
        id: 'p2',
        name: 'A2 Desi Cow Milk',
        unit: 'L',
        price: 90,
        emoji: '🍼',
        isMilk: true,
      ),
      Product(
        id: 'p3',
        name: 'Fresh Curd',
        unit: 'kg',
        price: 80,
        stock: 12,
        emoji: '🥣',
      ),
      Product(
        id: 'p4',
        name: 'Pure Desi Ghee',
        unit: 'kg',
        price: 750,
        stock: 4,
        lowStockAlert: 2,
        emoji: '🧈',
      ),
      Product(
        id: 'p5',
        name: 'Paneer',
        unit: 'kg',
        price: 380,
        stock: 3,
        lowStockAlert: 4,
        emoji: '🧀',
      ),
      Product(
        id: 'p6',
        name: 'Buttermilk',
        unit: 'L',
        price: 30,
        stock: 20,
        emoji: '🥤',
      ),
    ];

    cows = [
      Cow(
        id: 'k1',
        name: 'Gauri',
        tagNumber: 'PDF-001',
        breed: 'Gir',
        birthDate: DateTime(today.year - 5, 3, 10),
        status: CowStatus.milking,
        lastCalvingDate: today.subtract(const Duration(days: 90)),
      ),
      Cow(
        id: 'k2',
        name: 'Laxmi',
        tagNumber: 'PDF-002',
        breed: 'HF Cross',
        birthDate: DateTime(today.year - 4, 7, 2),
        status: CowStatus.milking,
      ),
      Cow(
        id: 'k3',
        name: 'Kamdhenu',
        tagNumber: 'PDF-003',
        breed: 'Sahiwal',
        birthDate: DateTime(today.year - 6, 1, 20),
        status: CowStatus.milking,
      ),
      Cow(
        id: 'k4',
        name: 'Nandini',
        tagNumber: 'PDF-004',
        breed: 'Jersey',
        birthDate: DateTime(today.year - 3, 11, 5),
        status: CowStatus.pregnant,
        expectedCalvingDate: today.add(const Duration(days: 42)),
      ),
      Cow(
        id: 'k5',
        name: 'Radha',
        tagNumber: 'PDF-005',
        breed: 'Gir',
        birthDate: DateTime(today.year - 7, 5, 15),
        status: CowStatus.dry,
      ),
      Cow(
        id: 'k6',
        name: 'Chhoti',
        tagNumber: 'PDF-006',
        breed: 'Gir',
        birthDate: today.subtract(const Duration(days: 150)),
        status: CowStatus.calf,
      ),
    ];

    vaccinations = [
      Vaccination(
        id: 'v1',
        cowId: 'k1',
        vaccine: 'FMD (Foot & Mouth)',
        dueDate: today.add(const Duration(days: 2)),
        vet: 'Dr. Kulkarni',
      ),
      Vaccination(
        id: 'v2',
        cowId: 'k2',
        vaccine: 'FMD (Foot & Mouth)',
        dueDate: today.add(const Duration(days: 2)),
        vet: 'Dr. Kulkarni',
      ),
      Vaccination(
        id: 'v3',
        cowId: 'k3',
        vaccine: 'HS (Haemorrhagic Septicaemia)',
        dueDate: today.subtract(const Duration(days: 3)),
        vet: 'Dr. Kulkarni',
      ),
      Vaccination(
        id: 'v4',
        cowId: 'k4',
        vaccine: 'Brucellosis',
        dueDate: today.add(const Duration(days: 12)),
      ),
      Vaccination(
        id: 'v5',
        cowId: 'k6',
        vaccine: 'Deworming',
        dueDate: today.add(const Duration(days: 5)),
      ),
      Vaccination(
        id: 'v6',
        cowId: 'k5',
        vaccine: 'Lumpy Skin (LSD)',
        dueDate: today.add(const Duration(days: 30)),
      ),
      Vaccination(
        id: 'v7',
        cowId: 'k1',
        vaccine: 'Lumpy Skin (LSD)',
        dueDate: today.subtract(const Duration(days: 60)),
        doneDate: today.subtract(const Duration(days: 60)),
        vet: 'Dr. Kulkarni',
      ),
      Vaccination(
        id: 'v8',
        cowId: 'k2',
        vaccine: 'HS (Haemorrhagic Septicaemia)',
        dueDate: today.subtract(const Duration(days: 40)),
        doneDate: today.subtract(const Duration(days: 39)),
      ),
    ];

    milk = [];
    sales = [];
    payments = [];
    expenses = [];
    orders = [];

    final base = {'k1': 7.0, 'k2': 9.0, 'k3': 6.0};
    for (var d = 13; d >= 0; d--) {
      final day = today.subtract(Duration(days: d));
      base.forEach((cow, b) {
        for (final shift in Shift.values) {
          if (d == 0 && shift == Shift.evening) {
            continue; // evening not milked yet
          }
          milk.add(
            MilkRecord(
              id: newId(),
              cowId: cow,
              date: day.add(Duration(hours: shift == Shift.morning ? 6 : 18)),
              shift: shift,
              liters: double.parse(
                (b + rnd.nextDouble() * 2 - 1).toStringAsFixed(1),
              ),
              fat: double.parse((3.8 + rnd.nextDouble()).toStringAsFixed(1)),
            ),
          );
        }
      });

      // Subscription deliveries (credit) for past days.
      if (d > 0) {
        for (final c in users.where((u) => u.dailyLiters > 0)) {
          final p = products.firstWhere((p) => p.id == c.subscriptionProductId);
          sales.add(
            Sale(
              id: newId(),
              customerId: c.id,
              customerName: c.name,
              productId: p.id,
              productName: p.name,
              unit: p.unit,
              quantity: c.dailyLiters,
              rate: p.price,
              date: day.add(const Duration(hours: 7)),
              mode: PaymentMode.credit,
              orderId: _subRef(day),
            ),
          );
        }
      }

      // Walk-in counter sales.
      sales.add(
        Sale(
          id: newId(),
          customerName: 'Walk-in',
          productId: 'p1',
          productName: 'Cow Milk',
          unit: 'L',
          quantity: (4 + rnd.nextInt(6)).toDouble(),
          rate: 60,
          date: day.add(const Duration(hours: 9)),
          mode: rnd.nextBool() ? PaymentMode.cash : PaymentMode.upi,
        ),
      );
      if (d % 3 == 0) {
        sales.add(
          Sale(
            id: newId(),
            customerName: 'Walk-in',
            productId: 'p3',
            productName: 'Fresh Curd',
            unit: 'kg',
            quantity: 2,
            rate: 80,
            date: day.add(const Duration(hours: 10)),
            mode: PaymentMode.cash,
          ),
        );
      }
      if (d % 2 == 0) {
        expenses.add(
          Expense(
            id: newId(),
            category: d % 4 == 0 ? 'Feed & Fodder' : 'Labour',
            amount: d % 4 == 0 ? 1800 : 500,
            date: day,
            note: d % 4 == 0 ? 'Cattle feed bags' : 'Helper wages',
          ),
        );
      }
    }
    expenses.add(
      Expense(
        id: newId(),
        category: 'Medicine & Vet',
        amount: 1200,
        date: today.subtract(const Duration(days: 6)),
        note: 'Vet visit',
      ),
    );
    expenses.add(
      Expense(
        id: newId(),
        category: 'Electricity',
        amount: 950,
        date: today.subtract(const Duration(days: 10)),
      ),
    );

    payments = [
      Payment(
        id: newId(),
        customerId: 'c1',
        amount: 1000,
        date: today.subtract(const Duration(days: 5)),
        mode: PaymentMode.upi,
      ),
      Payment(
        id: newId(),
        customerId: 'c3',
        amount: 6000,
        date: today.subtract(const Duration(days: 3)),
        mode: PaymentMode.cash,
      ),
      Payment(
        id: newId(),
        customerId: 'c2',
        amount: 780,
        date: today.subtract(const Duration(days: 1)),
        mode: PaymentMode.upi,
      ),
    ];

    orders = [
      Order(
        id: newId(),
        customerId: 'c1',
        customerName: 'Ramesh Patil',
        items: [
          OrderItem(
            productId: 'p4',
            productName: 'Pure Desi Ghee',
            unit: 'kg',
            quantity: 0.5,
            rate: 750,
          ),
          OrderItem(
            productId: 'p3',
            productName: 'Fresh Curd',
            unit: 'kg',
            quantity: 1,
            rate: 80,
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        deliveryDate: today.add(const Duration(days: 1)),
        note: 'Please deliver with morning milk',
      ),
      Order(
        id: newId(),
        customerId: 'c3',
        customerName: 'Hotel Sai Krupa',
        items: [
          OrderItem(
            productId: 'p5',
            productName: 'Paneer',
            unit: 'kg',
            quantity: 2,
            rate: 380,
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        deliveryDate: today,
        status: OrderStatus.accepted,
      ),
    ];

    final nowTime = DateTime.now();
    posts = [
      FarmPost(
        id: newId(),
        title: 'Milk rate update from 1st',
        note:
            'Dear customers, due to rising fodder costs, cow milk will be ₹62/L from the 1st of next month. A2 milk stays at ₹90/L. Thank you for your support 🙏',
        category: 'notice',
        createdAt: nowTime.subtract(const Duration(hours: 3)),
        pinned: true,
      ),
      FarmPost(
        id: newId(),
        title: 'Morning shed wash done ✨',
        note:
            'Every day at 5 AM we wash the full shed with water and phenyl, remove dung and lay fresh dry bedding. Clean shed = healthy cows = pure milk.',
        category: 'cleaning',
        createdAt: nowTime.subtract(const Duration(hours: 6)),
        likes: ['c1', 'c3'],
      ),
      FarmPost(
        id: newId(),
        title: 'How we milk Gauri',
        note:
            'Udder washed with warm water, wiped with a clean cloth, first drops discarded, then milked into a sterilised steel can. No hand ever touches the milk.',
        category: 'milking',
        createdAt: nowTime.subtract(const Duration(days: 1, hours: 2)),
        likes: ['c2'],
      ),
      FarmPost(
        id: newId(),
        title: 'Fresh green fodder today',
        note:
            'Our cows ate fresh maize and lucerne from our own field today, plus mineral mix. No hormones, no injections for milk.',
        category: 'feeding',
        createdAt: nowTime.subtract(const Duration(days: 2)),
        likes: ['c1', 'c2', 'c4'],
      ),
      FarmPost(
        id: newId(),
        title: 'FMD vaccination this week',
        note:
            'Dr. Kulkarni will vaccinate the whole herd against Foot & Mouth disease. Healthy cows give safe milk.',
        category: 'health',
        createdAt: nowTime.subtract(const Duration(days: 3)),
      ),
    ];

    hygiene = [
      for (var d = 9; d >= 1; d--)
        HygieneLog(
          date: today.subtract(Duration(days: d)),
          done: [
            for (final i in hygieneItems)
              if (d != 7 || i.key != 'water') i.key,
          ],
        ),
      HygieneLog(
        date: today,
        done: ['shed', 'udder', 'hands', 'utensils', 'filter'],
      ),
    ];

    save();
  }
}

/// Makes the [AppStore] available to the widget tree and rebuilds dependents
/// whenever it changes.
class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child})
    : super(notifier: store);

  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  static AppStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
