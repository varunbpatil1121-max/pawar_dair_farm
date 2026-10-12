import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cow_farm/data/store.dart';
import 'package:cow_farm/main.dart';
import 'package:cow_farm/models/models.dart';

Future<AppStore> freshStore() async {
  SharedPreferences.setMockInitialValues({});
  final store = AppStore();
  await store.load();
  return store;
}

void main() {
  test('login checks phone and password', () async {
    final store = await freshStore();
    expect(store.login('9999999999', 'wrong'), 'Wrong password');
    expect(store.login('0000000000', 'x'), isNotNull);
    expect(store.login('9999999999', 'admin123'), isNull);
    expect(store.currentUser!.isAdmin, isTrue);
  });

  test('credit delivery raises balance, payment lowers it', () async {
    final store = await freshStore();
    final c = store.userById('c2')!;
    final before = store.balanceOf(c.id);
    final day = DateTime.now();
    store.undoDelivery(c.id, day);
    store.markDelivered(c, day);
    store.markDelivered(c, day); // idempotent
    final price = store.productById(c.subscriptionProductId)!.price;
    expect(
      store.balanceOf(c.id),
      closeTo(before + price * c.dailyLiters, 0.01),
    );
    store.addPayment(Payment(id: 'x', customerId: c.id, amount: 50, date: day));
    expect(
      store.balanceOf(c.id),
      closeTo(before + price * c.dailyLiters - 50, 0.01),
    );
  });

  test('delivering an order books sales and reduces stock', () async {
    final store = await freshStore();
    final ghee = store.productById('p4')!;
    final stockBefore = ghee.stock;
    final order = store.orders.firstWhere(
      (o) => o.status == OrderStatus.pending,
    );
    store.setOrderStatus(order, OrderStatus.delivered);
    expect(ghee.stock, stockBefore - 0.5);
    expect(
      store.sales.where((s) => s.orderId == order.id).length,
      order.items.length,
    );
  });

  test('skipped customers drop off the delivery list', () async {
    final store = await freshStore();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final c = store.userById('c1')!;
    expect(store.subscribersFor(tomorrow).contains(c), isTrue);
    store.toggleSkip(c, tomorrow);
    expect(store.subscribersFor(tomorrow).contains(c), isFalse);
  });

  test('hygiene checklist and streak', () async {
    final store = await freshStore();
    // Demo data: days 1-6 complete, day 7 missing one step, today partial.
    expect(store.hygieneStreak, 6);
    for (final i in hygieneItems) {
      if (!store.hygieneToday().done.contains(i.key)) {
        store.toggleHygiene(i.key);
      }
    }
    expect(store.hygieneToday().complete, isTrue);
    expect(store.hygieneStreak, 7);
  });

  test('customers can like and unlike posts; admin can delete', () async {
    final store = await freshStore();
    final post = store.feed.first;
    expect(post.pinned, isTrue); // pinned notice comes first
    final n = post.likes.length;
    store.toggleLike(post, 'c4');
    expect(post.likes.length, n + 1);
    store.toggleLike(post, 'c4');
    expect(post.likes.length, n);
    store.deletePost(post);
    expect(store.posts.contains(post), isFalse);
  });

  for (final size in const [Size(390, 844), Size(360, 740)]) {
    testWidgets(
      'admin and customer can log in and see their home at ${size.width.toInt()}px',
      (tester) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        final store = await freshStore();
        await tester.pumpWidget(
          StoreScope(store: store, child: const PawarDairyApp()),
        );
        expect(find.text('Pawar Dairy'), findsOneWidget);

        // Admin
        await tester.tap(find.text('Admin'));
        await tester.pump();
        await tester.ensureVisible(find.text('Use demo account'));
        await tester.tap(find.text('Use demo account'));
        await tester.pump();
        await tester.ensureVisible(find.text('Login as Admin'));
        await tester.tap(find.text('Login as Admin'));
        await tester.pumpAndSettle();
        expect(find.text('Today\'s milk'), findsOneWidget);

        for (final tab in ['Cattle', 'Milk', 'Sales', 'More']) {
          await tester.tap(find.text(tab).last);
          await tester.pumpAndSettle();
        }
        expect(find.text('Customers'), findsWidgets);

        await tester.tap(find.text('Farm Diary'));
        await tester.pumpAndSettle();
        expect(find.text('Milk rate update from 1st'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Hygiene'));
        await tester.pumpAndSettle();
        expect(find.text('Tick each step as you finish it'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Customer
        store.logout();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Use demo account'));
        await tester.tap(find.text('Use demo account'));
        await tester.pump();
        await tester.ensureVisible(find.text('Login as Customer'));
        await tester.tap(find.text('Login as Customer'));
        await tester.pumpAndSettle();
        expect(find.text('From the farm'), findsOneWidget);
        await tester.tap(find.text('Farm').last);
        await tester.pumpAndSettle();
        expect(find.text('Today\'s hygiene score'), findsOneWidget);
        for (final tab in ['Shop', 'Orders', 'Bills']) {
          await tester.tap(find.text(tab).last);
          await tester.pumpAndSettle();
        }
        expect(find.text('Bills & payments'), findsOneWidget);
      },
    );
  }
}
