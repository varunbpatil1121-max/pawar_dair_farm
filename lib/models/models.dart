// Data models for Pawar Dairy. Every model serialises to/from JSON so the
// store can persist it locally (and later sync it to a cloud backend).

enum UserRole { admin, customer }

enum CowStatus { milking, dry, pregnant, calf, sick }

enum Shift { morning, evening }

enum OrderStatus { pending, accepted, delivered, cancelled }

enum PaymentMode { cash, upi, credit }

T _enum<T extends Enum>(List<T> values, String? name, T fallback) =>
    values.firstWhere((e) => e.name == name, orElse: () => fallback);

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class AppUser {
  final String id;
  String name;
  String phone; // used as login id
  String password;
  UserRole role;
  String address;
  double dailyLiters; // daily milk subscription (customers)
  String? subscriptionProductId;
  List<DateTime> skipDates; // days the customer paused delivery
  bool active;
  DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.password,
    required this.role,
    this.address = '',
    this.dailyLiters = 0,
    this.subscriptionProductId,
    List<DateTime>? skipDates,
    this.active = true,
    DateTime? createdAt,
  }) : skipDates = skipDates ?? [],
       createdAt = createdAt ?? DateTime.now();

  bool get isAdmin => role == UserRole.admin;

  bool skips(DateTime day) => skipDates.any((d) => sameDay(d, day));

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'password': password,
    'role': role.name,
    'address': address,
    'dailyLiters': dailyLiters,
    'subscriptionProductId': subscriptionProductId,
    'skipDates': skipDates.map((d) => d.toIso8601String()).toList(),
    'active': active,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'],
    name: j['name'],
    phone: j['phone'],
    password: j['password'],
    role: _enum(UserRole.values, j['role'], UserRole.customer),
    address: j['address'] ?? '',
    dailyLiters: (j['dailyLiters'] ?? 0).toDouble(),
    subscriptionProductId: j['subscriptionProductId'],
    skipDates: ((j['skipDates'] ?? []) as List)
        .map((s) => DateTime.parse(s))
        .toList(),
    active: j['active'] ?? true,
    createdAt: DateTime.tryParse(j['createdAt'] ?? ''),
  );
}

class Cow {
  final String id;
  String name;
  String tagNumber;
  String breed;
  DateTime? birthDate;
  CowStatus status;
  String notes;
  DateTime? lastCalvingDate;
  DateTime? expectedCalvingDate;

  Cow({
    required this.id,
    required this.name,
    required this.tagNumber,
    required this.breed,
    this.birthDate,
    this.status = CowStatus.milking,
    this.notes = '',
    this.lastCalvingDate,
    this.expectedCalvingDate,
  });

  String get ageLabel {
    if (birthDate == null) return 'Age unknown';
    final months = DateTime.now().difference(birthDate!).inDays ~/ 30;
    if (months < 12) return '$months mo';
    final y = months ~/ 12, m = months % 12;
    return m == 0 ? '$y yr' : '$y yr $m mo';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tagNumber': tagNumber,
    'breed': breed,
    'birthDate': birthDate?.toIso8601String(),
    'status': status.name,
    'notes': notes,
    'lastCalvingDate': lastCalvingDate?.toIso8601String(),
    'expectedCalvingDate': expectedCalvingDate?.toIso8601String(),
  };

  factory Cow.fromJson(Map<String, dynamic> j) => Cow(
    id: j['id'],
    name: j['name'],
    tagNumber: j['tagNumber'] ?? '',
    breed: j['breed'] ?? '',
    birthDate: DateTime.tryParse(j['birthDate'] ?? ''),
    status: _enum(CowStatus.values, j['status'], CowStatus.milking),
    notes: j['notes'] ?? '',
    lastCalvingDate: DateTime.tryParse(j['lastCalvingDate'] ?? ''),
    expectedCalvingDate: DateTime.tryParse(j['expectedCalvingDate'] ?? ''),
  );
}

class MilkRecord {
  final String id;
  String cowId;
  DateTime date;
  Shift shift;
  double liters;
  double? fat; // fat %

  MilkRecord({
    required this.id,
    required this.cowId,
    required this.date,
    required this.shift,
    required this.liters,
    this.fat,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'cowId': cowId,
    'date': date.toIso8601String(),
    'shift': shift.name,
    'liters': liters,
    'fat': fat,
  };

  factory MilkRecord.fromJson(Map<String, dynamic> j) => MilkRecord(
    id: j['id'],
    cowId: j['cowId'],
    date: DateTime.parse(j['date']),
    shift: _enum(Shift.values, j['shift'], Shift.morning),
    liters: (j['liters'] ?? 0).toDouble(),
    fat: (j['fat'] as num?)?.toDouble(),
  );
}

class Vaccination {
  final String id;
  String cowId;
  String vaccine;
  DateTime dueDate;
  DateTime? doneDate;
  String vet;
  String notes;

  Vaccination({
    required this.id,
    required this.cowId,
    required this.vaccine,
    required this.dueDate,
    this.doneDate,
    this.vet = '',
    this.notes = '',
  });

  bool get isDone => doneDate != null;

  bool get isOverdue =>
      !isDone && dateOnly(dueDate).isBefore(dateOnly(DateTime.now()));

  int get daysUntilDue =>
      dateOnly(dueDate).difference(dateOnly(DateTime.now())).inDays;

  Map<String, dynamic> toJson() => {
    'id': id,
    'cowId': cowId,
    'vaccine': vaccine,
    'dueDate': dueDate.toIso8601String(),
    'doneDate': doneDate?.toIso8601String(),
    'vet': vet,
    'notes': notes,
  };

  factory Vaccination.fromJson(Map<String, dynamic> j) => Vaccination(
    id: j['id'],
    cowId: j['cowId'],
    vaccine: j['vaccine'],
    dueDate: DateTime.parse(j['dueDate']),
    doneDate: DateTime.tryParse(j['doneDate'] ?? ''),
    vet: j['vet'] ?? '',
    notes: j['notes'] ?? '',
  );
}

class Product {
  final String id;
  String name;
  String unit; // L, kg, g, pcs
  double price;
  double stock;
  double lowStockAlert;
  String emoji;
  bool available;
  bool isMilk; // stock comes from milk collection

  Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    this.stock = 0,
    this.lowStockAlert = 5,
    this.emoji = '🥛',
    this.available = true,
    this.isMilk = false,
  });

  bool get isLowStock => !isMilk && stock <= lowStockAlert;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'unit': unit,
    'price': price,
    'stock': stock,
    'lowStockAlert': lowStockAlert,
    'emoji': emoji,
    'available': available,
    'isMilk': isMilk,
  };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'],
    name: j['name'],
    unit: j['unit'] ?? 'L',
    price: (j['price'] ?? 0).toDouble(),
    stock: (j['stock'] ?? 0).toDouble(),
    lowStockAlert: (j['lowStockAlert'] ?? 5).toDouble(),
    emoji: j['emoji'] ?? '🥛',
    available: j['available'] ?? true,
    isMilk: j['isMilk'] ?? false,
  );
}

class Sale {
  final String id;
  String? customerId; // null = walk-in customer
  String customerName;
  String productId;
  String productName;
  String unit;
  double quantity;
  double rate;
  DateTime date;
  PaymentMode mode;
  String? orderId;

  Sale({
    required this.id,
    this.customerId,
    required this.customerName,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.rate,
    required this.date,
    this.mode = PaymentMode.cash,
    this.orderId,
  });

  double get total => quantity * rate;

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'customerName': customerName,
    'productId': productId,
    'productName': productName,
    'unit': unit,
    'quantity': quantity,
    'rate': rate,
    'date': date.toIso8601String(),
    'mode': mode.name,
    'orderId': orderId,
  };

  factory Sale.fromJson(Map<String, dynamic> j) => Sale(
    id: j['id'],
    customerId: j['customerId'],
    customerName: j['customerName'] ?? 'Walk-in',
    productId: j['productId'],
    productName: j['productName'] ?? '',
    unit: j['unit'] ?? 'L',
    quantity: (j['quantity'] ?? 0).toDouble(),
    rate: (j['rate'] ?? 0).toDouble(),
    date: DateTime.parse(j['date']),
    mode: _enum(PaymentMode.values, j['mode'], PaymentMode.cash),
    orderId: j['orderId'],
  );
}

class OrderItem {
  String productId;
  String productName;
  String unit;
  double quantity;
  double rate;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.rate,
  });

  double get total => quantity * rate;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'unit': unit,
    'quantity': quantity,
    'rate': rate,
  };

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
    productId: j['productId'],
    productName: j['productName'],
    unit: j['unit'],
    quantity: (j['quantity'] ?? 0).toDouble(),
    rate: (j['rate'] ?? 0).toDouble(),
  );
}

class Order {
  final String id;
  String customerId;
  String customerName;
  List<OrderItem> items;
  DateTime createdAt;
  DateTime deliveryDate;
  OrderStatus status;
  String note;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.createdAt,
    required this.deliveryDate,
    this.status = OrderStatus.pending,
    this.note = '',
  });

  double get total => items.fold(0, (s, i) => s + i.total);

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'customerName': customerName,
    'items': items.map((i) => i.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'deliveryDate': deliveryDate.toIso8601String(),
    'status': status.name,
    'note': note,
  };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: j['id'],
    customerId: j['customerId'],
    customerName: j['customerName'] ?? '',
    items: ((j['items'] ?? []) as List)
        .map((i) => OrderItem.fromJson(Map<String, dynamic>.from(i)))
        .toList(),
    createdAt: DateTime.parse(j['createdAt']),
    deliveryDate: DateTime.parse(j['deliveryDate']),
    status: _enum(OrderStatus.values, j['status'], OrderStatus.pending),
    note: j['note'] ?? '',
  );
}

class Payment {
  final String id;
  String customerId;
  double amount;
  DateTime date;
  PaymentMode mode;
  String note;

  Payment({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.date,
    this.mode = PaymentMode.cash,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'amount': amount,
    'date': date.toIso8601String(),
    'mode': mode.name,
    'note': note,
  };

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
    id: j['id'],
    customerId: j['customerId'],
    amount: (j['amount'] ?? 0).toDouble(),
    date: DateTime.parse(j['date']),
    mode: _enum(PaymentMode.values, j['mode'], PaymentMode.cash),
    note: j['note'] ?? '',
  );
}

const expenseCategories = [
  'Feed & Fodder',
  'Medicine & Vet',
  'Labour',
  'Electricity',
  'Equipment',
  'Transport',
  'Other',
];

class Expense {
  final String id;
  String category;
  double amount;
  DateTime date;
  String note;

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
    id: j['id'],
    category: j['category'] ?? 'Other',
    amount: (j['amount'] ?? 0).toDouble(),
    date: DateTime.parse(j['date']),
    note: j['note'] ?? '',
  );
}

// ------------------------------------------------------------ farm feed

enum MediaType { none, image, video }

/// Categories for farm updates shown to customers.
class PostCategory {
  final String key;
  final String label;
  final String emoji;
  final int color; // ARGB
  const PostCategory(this.key, this.label, this.emoji, this.color);
}

const postCategories = [
  PostCategory('cleaning', 'Cleaning', '🧼', 0xFF1E9E9A),
  PostCategory('milking', 'Milking', '🥛', 0xFF3B8BD9),
  PostCategory('feeding', 'Feeding', '🌾', 0xFFC98A2B),
  PostCategory('health', 'Cattle care', '🩺', 0xFFE25C5C),
  PostCategory('farm', 'Farm life', '🐄', 0xFF2E7D4F),
  PostCategory('notice', 'Notice', '📢', 0xFF8A63D2),
];

PostCategory categoryOf(String key) => postCategories.firstWhere(
  (c) => c.key == key,
  orElse: () => postCategories[4],
);

class FarmPost {
  final String id;
  String title;
  String note;
  String category;
  MediaType mediaType;
  String? mediaPath;
  DateTime createdAt;
  bool pinned;
  List<String> likes; // user ids

  FarmPost({
    required this.id,
    required this.title,
    required this.note,
    required this.category,
    this.mediaType = MediaType.none,
    this.mediaPath,
    required this.createdAt,
    this.pinned = false,
    List<String>? likes,
  }) : likes = likes ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'note': note,
    'category': category,
    'mediaType': mediaType.name,
    'mediaPath': mediaPath,
    'createdAt': createdAt.toIso8601String(),
    'pinned': pinned,
    'likes': likes,
  };

  factory FarmPost.fromJson(Map<String, dynamic> j) => FarmPost(
    id: j['id'],
    title: j['title'] ?? '',
    note: j['note'] ?? '',
    category: j['category'] ?? 'farm',
    mediaType: _enum(MediaType.values, j['mediaType'], MediaType.none),
    mediaPath: j['mediaPath'],
    createdAt: DateTime.parse(j['createdAt']),
    pinned: j['pinned'] ?? false,
    likes: List<String>.from(j['likes'] ?? []),
  );
}

// ------------------------------------------------------- hygiene checklist

class HygieneItem {
  final String key;
  final String label;
  final String emoji;
  const HygieneItem(this.key, this.label, this.emoji);
}

const hygieneItems = [
  HygieneItem('shed', 'Shed washed & dung removed', '🧹'),
  HygieneItem('udder', 'Udders washed & dried before milking', '💧'),
  HygieneItem('hands', 'Milker hands washed, clean clothes', '🧼'),
  HygieneItem('utensils', 'Cans & utensils sterilised in hot water', '♨️'),
  HygieneItem('filter', 'Milk filtered through clean cloth', '🫗'),
  HygieneItem('chill', 'Milk chilled within 1 hour', '❄️'),
  HygieneItem('water', 'Fresh drinking water for cattle', '🚰'),
];

class HygieneLog {
  DateTime date;
  List<String> done;
  String note;

  HygieneLog({required this.date, List<String>? done, this.note = ''})
    : done = done ?? [];

  int get score =>
      done.where((k) => hygieneItems.any((i) => i.key == k)).length;
  bool get complete => score == hygieneItems.length;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'done': done,
    'note': note,
  };

  factory HygieneLog.fromJson(Map<String, dynamic> j) => HygieneLog(
    date: DateTime.parse(j['date']),
    done: List<String>.from(j['done'] ?? []),
    note: j['note'] ?? '',
  );
}
