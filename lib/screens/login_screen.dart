import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _asAdmin = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final store = StoreScope.read(context);
    final err = store.login(_phone.text, _password.text);
    if (err == null && store.currentUser!.isAdmin != _asAdmin) {
      store.logout();
      setState(
        () => _error = _asAdmin
            ? 'This is a customer account. Switch to Customer login.'
            : 'This is the farm owner account. Switch to Admin login.',
      );
      return;
    }
    setState(() => _error = err);
  }

  void _fillDemo() {
    setState(() {
      _phone.text = _asAdmin ? '9999999999' : '9876543210';
      _password.text = _asAdmin ? 'admin123' : '1234';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0E3320), AppColors.greenDark, AppColors.green],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(top: -80, right: -60, child: _Blob(240, 0.07)),
            const Positioned(top: 160, left: -90, child: _Blob(200, 0.05)),
            const Positioned(bottom: -100, right: -40, child: _Blob(280, 0.06)),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '🐄',
                            style: TextStyle(fontSize: 52),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Pawar Dairy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fresh milk from our farm to your home',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _TrustChip('🧼 Hygienic'),
                            _TrustChip('🌾 Farm fresh'),
                            _TrustChip('🚚 Daily delivery'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SegmentedButton<bool>(
                                  segments: const [
                                    ButtonSegment(
                                      value: false,
                                      icon: Icon(Icons.person_outline),
                                      label: Text('Customer'),
                                    ),
                                    ButtonSegment(
                                      value: true,
                                      icon: Icon(
                                        Icons.admin_panel_settings_outlined,
                                      ),
                                      label: Text('Admin'),
                                    ),
                                  ],
                                  selected: {_asAdmin},
                                  onSelectionChanged: (s) => setState(() {
                                    _asAdmin = s.first;
                                    _error = null;
                                  }),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: _phone,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone number',
                                    prefixIcon: Icon(Icons.phone_outlined),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _password,
                                  obscureText: _obscure,
                                  onSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _error!,
                                    style: TextStyle(
                                      color: cs.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                FilledButton(
                                  onPressed: _submit,
                                  child: Text(
                                    _asAdmin
                                        ? 'Login as Admin'
                                        : 'Login as Customer',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _fillDemo,
                                  child: const Text('Use demo account'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _asAdmin
                              ? 'Admin manages cattle, milk, sales & customers'
                              : 'New customer? Ask the farm to create your account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final double alpha;
  const _Blob(this.size, this.alpha);

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );
}

class _TrustChip extends StatelessWidget {
  final String text;
  const _TrustChip(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white24),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
