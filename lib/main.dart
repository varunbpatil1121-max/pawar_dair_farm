import 'package:flutter/material.dart';

import 'data/store.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/customer/customer_shell.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.load();
  runApp(StoreScope(store: store, child: const PawarDairyApp()));
}

class PawarDairyApp extends StatelessWidget {
  const PawarDairyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final user = StoreScope.of(context).currentUser;
    return MaterialApp(
      title: 'Pawar Dairy',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: user == null
            ? const LoginScreen()
            : user.isAdmin
            ? const AdminShell()
            : const CustomerShell(),
      ),
    );
  }
}
