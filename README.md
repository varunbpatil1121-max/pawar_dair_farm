# 🐄 Pawar Dairy

A Flutter app for running a small dairy farm. The farmer (admin) manages cattle, milk, sales and customers. Customers check their bills, order products, pause deliveries and watch videos showing how their milk is produced.

## Features

### Admin (farmer)
- **Dashboard:** liters collected today (morning and evening), liters sold, milk left, earnings compared with yesterday, customer dues, delivery progress, new orders and 7-day charts.
- **Cattle:** a profile for each cow (breed, age, status, calving dates), daily milk average and fat %.
- **Vaccinations:** schedule for one cow or the whole herd, with overdue and due-this-week alerts.
- **Milk collection:** enter liters for every cow in one go, separately for morning and evening.
- **Sales:** cash, UPI or credit sales to walk-in or registered customers.
- **Products and stock:** milk, curd, ghee, paneer and more, with low-stock alerts.
- **Customers:** login accounts, daily milk amount, account history, payments, and a monthly bill to copy into WhatsApp.
- **Daily deliveries:** a delivery checklist; each tick adds the milk to that customer's bill.
- **Orders, expenses and reports:** monthly profit, cost per liter, top cows and top customers.
- **Farm Diary:** post videos and photos of cleaning, milking and feeding, with notes for customers.
- **Hygiene checklist:** 7 daily cleanliness steps, with a clean-days streak.

### Customer
- Amount due, monthly bill and payment history, with UPI payment details.
- Pause daily milk for any of the next 7 days.
- Shop for dairy products and track orders.
- Farm feed with videos and photos, plus today's hygiene score and milk fat %.

## Getting started

Requires Flutter 3.44 or newer.

```bash
flutter pub get
flutter run
```

On first launch the app loads sample data. Tap **Use demo account** on the login screen, or enter:

| Role     | Phone        | Password   |
|----------|--------------|------------|
| Admin    | `9999999999` | `admin123` |
| Customer | `9876543210` | `1234`     |

To start using real data, go to **More → Settings → Start fresh**, then change the admin password.

## Project structure

```
lib/
  main.dart              App entry; picks the admin or customer screens after login
  theme.dart             Colours, font, number and date formatting
  models/models.dart     Data classes (cows, sales, orders, posts, ...)
  data/store.dart        App state, saving and business logic
  services/media.dart    Picking and storing photos and videos
  widgets/               Shared UI pieces (cards, charts, video player)
  screens/
    login_screen.dart
    admin/               Admin screens
    customer/            Customer screens
    feed/                Farm Diary and hygiene checklist (shared)
```

Run the tests with `flutter test`.

## Current limitation

All data, including photos and videos, is saved only on the phone where it was entered. For the admin's phone and customers' phones to share data, the next step is a cloud backend such as Firebase. Only `lib/data/store.dart` needs to change for that.
