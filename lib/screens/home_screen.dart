import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../data.dart';
import '../models.dart';
import '../main.dart';
import 'order_screen.dart';
import 'summary_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'edit_menu_screen.dart';
import '../widgets/footer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late PageController _pageController;

  String _adminPassword = '1234';
  String _hotelName = 'NAMMA HOTEL';
  int _currentPage = 0; // 0 = Menu, 1 = Tables

  // ── Order cart ──────────────────────────────────────────────────────────
  final Map<String, int> _orderCart = {}; // item name → qty
  int _orderCount = 0; // how many order bills confirmed today

  double get _orderTotal => _orderCart.entries.fold(0, (sum, e) {
    final item = menu.firstWhere((m) => m.name == e.key, orElse: () => Item(e.key, 0));
    return sum + item.price * e.value;
  });

  void _orderAdd(Item item) => setState(() => _orderCart[item.name] = (_orderCart[item.name] ?? 0) + 1);
  void _orderRemove(Item item) => setState(() {
    if ((_orderCart[item.name] ?? 0) > 1) {
      _orderCart[item.name] = _orderCart[item.name]! - 1;
    } else {
      _orderCart.remove(item.name);
    }
  });

  void refresh() => setState(() {});

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _pageController = PageController(initialPage: 0);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminPassword = prefs.getString('adminPassword') ?? '1234';
      _hotelName = (prefs.getString('hotelName') ?? 'NAMMA HOTEL').toUpperCase();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: thCard,
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
            ),
            const SizedBox(width: 10),
            const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          ],
        ),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.w600)),
          ),
          GestureDetector(
            onTap: () { Navigator.pop(context); _logout(); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
              child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: thCard,
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.lock_reset_rounded, size: 18, color: Color(0xFFE87722)),
            ),
            const SizedBox(width: 10),
            const Text('Change Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPwController, obscureText: true, keyboardType: TextInputType.number,
              decoration: _pwInputDecoration('New Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPwController, obscureText: true, keyboardType: TextInputType.number,
              decoration: _pwInputDecoration('Confirm Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.w600)),
          ),
          GestureDetector(
            onTap: () async {
              if (newPwController.text.isNotEmpty && newPwController.text == confirmPwController.text) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('adminPassword', newPwController.text);
                setState(() => _adminPassword = newPwController.text);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('✅ Password changed successfully!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFF2ECC71),
                ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('❌ Passwords do not match!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFFE74C3C),
                ));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFB347), Color(0xFFE87722)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  InputDecoration _pwInputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14, fontWeight: FontWeight.w400),
    filled: true, fillColor: thInput,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1.2)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE87722), width: 1.8)),
  );

  void _showChangePasswordOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: thCard,
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.lock_open_rounded, size: 18, color: Color(0xFF2ECC71)),
            ),
            const SizedBox(width: 10),
            const Text('Access Granted 🔓', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          ],
        ),
        content: const Text('Do you want to change your admin password?',
            style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => EditMenuScreen(
                  gradientColors: const [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
                  accentColor: const Color(0xFFE87722),
                ),
              )).then((_) => refresh());
            },
            child: const Text('No, continue', style: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.w600)),
          ),
          GestureDetector(
            onTap: () { Navigator.pop(context); _showChangePasswordDialog(); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFB347), Color(0xFFE87722)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Yes, change', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  void _showPasswordDialog() {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: thCard,
              title: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFFE87722)),
                  ),
                  const SizedBox(width: 10),
                  const Text('Admin Access', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter password to edit menu', style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: true, autofocus: true, keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A), letterSpacing: 4),
                    decoration: InputDecoration(
                      hintText: '••••',
                      hintStyle: const TextStyle(color: Color(0xFFCCCCCC), letterSpacing: 4),
                      filled: true, fillColor: thInput,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1.2)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE87722), width: 1.8)),
                    ),
                    onSubmitted: (_) => _validateAndNavigate(context, passwordController, setDialogState),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () { passwordController.dispose(); Navigator.pop(context); },
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.w600)),
                ),
                GestureDetector(
                  onTap: () => _validateAndNavigate(context, passwordController, setDialogState),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFB347), Color(0xFFE87722)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            );
          },
        );
      },
    );
  }

  void _validateAndNavigate(BuildContext context, TextEditingController controller, StateSetter setDialogState) {
    if (controller.text == _adminPassword) {
      Navigator.pop(context);
      _showChangePasswordOption();
    } else {
      setDialogState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('❌ Wrong password. Try again.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFFE74C3C),
        duration: Duration(seconds: 2),
      ));
      controller.clear();
    }
  }


  void _showSettingsPasswordDialog() {
    final ctrl = TextEditingController();
    bool wrongPassword = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: thCard,
          title: Row(children: [
            Container(width: 36, height: 36,
                decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.settings_rounded, size: 18, color: Color(0xFFE87722))),
            const SizedBox(width: 10),
            Text("Settings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: thTxtMain)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Enter admin password to continue", style: TextStyle(fontSize: 13, color: thTxtSub)),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                obscureText: true,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: thTxtMain, letterSpacing: 4),
                decoration: InputDecoration(
                  hintText: "••••",
                  hintStyle: TextStyle(color: thTxtSub, letterSpacing: 4),
                  filled: true,
                  fillColor: wrongPassword ? const Color(0xFFFFEBEB) : thInput,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: wrongPassword ? const Color(0xFFE74C3C) : thBorder, width: 1.2)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: wrongPassword ? const Color(0xFFE74C3C) : const Color(0xFFE87722), width: 1.8)),
                ),
                onSubmitted: (_) {
                  if (ctrl.text == _adminPassword) {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(
                      adminPassword: _adminPassword, hotelName: _hotelName,
                      onChanged: () async { await _loadPrefs(); setState(() {}); },
                    ))).then((_) => setState(() {}));
                  } else { setDlg(() => wrongPassword = true); ctrl.clear(); }
                },
              ),
              if (wrongPassword) ...[
                const SizedBox(height: 8),
                const Text("❌ Wrong password", style: TextStyle(fontSize: 12, color: Color(0xFFE74C3C), fontWeight: FontWeight.w600)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () { ctrl.dispose(); Navigator.pop(context); },
              child: Text("Cancel", style: TextStyle(color: thTxtSub, fontWeight: FontWeight.w600)),
            ),
            GestureDetector(
              onTap: () {
                if (ctrl.text == _adminPassword) {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(
                    adminPassword: _adminPassword, hotelName: _hotelName,
                    onChanged: () async { await _loadPrefs(); setState(() {}); },
                  ))).then((_) => setState(() {}));
                } else { setDlg(() => wrongPassword = true); ctrl.clear(); }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFB347), Color(0xFFE87722)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text("Enter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double total = tables.fold<double>(0, (sum, t) => sum + t.dailyTotal) +
        subTables.values.expand((s) => s).fold<double>(0.0, (sum, t) => sum + t.dailyTotal);
    final int activeTables = tables
        .where((t) => t.isOccupied || (subTables[t.tableNo] ?? []).any((s) => s.isOccupied))
        .length;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: thBg,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                _buildHeader(activeTables),

                // ── Page indicator dots ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDot(0, 'Menu'),
                      const SizedBox(width: 8),
                      _buildDot(1, 'Tables'),
                    ],
                  ),
                ),

                // ── PageView: Menu (0) + Tables (1) ─────────────────────
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      _buildMenuPage(),
                      _buildTablesPage(activeTables),
                    ],
                  ),
                ),

                if (_currentPage == 1)
                  _buildBottomBar(total),
                const AppFooter(),
              ],
            ),
          ),
        ), // SafeArea
      ), // Scaffold
    ); // ValueListenableBuilder
  }

  // ── Dot indicator ────────────────────────────────────────────────────────
  Widget _buildDot(int index, String label) {
    final bool active = _currentPage == index;
    return GestureDetector(
      onTap: () => _pageController.animateToPage(index,
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE87722) : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF999999),
          ),
        ),
      ),
    );
  }

  // ── Menu Page (Order) ───────────────────────────────────────────────────
  Widget _buildMenuPage() {
    final hasItems = _orderCart.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Text('Menu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A), letterSpacing: 0.5)),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.fromLTRB(16, 0, 16, hasItems ? 8 : 16),
            itemCount: menu.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final item = menu[index];
              final qty = _orderCart[item.name] ?? 0;
              return _OrderMenuCard(
                item: item,
                qty: qty,
                onAdd: () => _orderAdd(item),
                onRemove: () => _orderRemove(item),
              );
            },
          ),
        ),

        // ── Order cart bottom bar ───────────────────────────────────────
        if (hasItems)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, -4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cart items preview
                ..._orderCart.entries.map((e) {
                  final item = menu.firstWhere((m) => m.name == e.key, orElse: () => Item(e.key, 0));
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(6)),
                          child: Text('×${e.value}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF444444))),
                        ),
                        const SizedBox(width: 12),
                        Text('₹${(item.price * e.value).toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE87722))),
                      ],
                    ),
                  );
                }),
                const Divider(height: 16, color: Color(0xFFEEEEEE)),
                // Total + Complete Bill button
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Order Total', style: TextStyle(fontSize: 12, color: Color(0xFF888888), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text('₹${_orderTotal.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A), height: 1)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: _showOrderPaymentSheet,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFB347), Color(0xFFE87722), Color(0xFFFF4500)],
                              begin: Alignment.centerLeft, end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: const Color(0xFFE87722).withValues(alpha: 0.40), blurRadius: 14, offset: const Offset(0, 5))],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Complete Bill', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Order Payment Sheet ──────────────────────────────────────────────────
  void _showOrderPaymentSheet() {
    String selectedPayment = 'Cash';
    final total = _orderTotal;
    final cartSnapshot = Map<String, int>.from(_orderCart);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheet) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: const Color(0xFFD8D8D8), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                // Header
                Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(11)),
                      child: const Icon(Icons.shopping_bag_rounded, size: 20, color: Color(0xFFE87722)),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Bill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                        Text('Review & confirm payment', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFEEEEEE)),
                const SizedBox(height: 10),

                // Items
                ...cartSnapshot.entries.map((e) {
                  final item = menu.firstWhere((m) => m.name == e.key, orElse: () => Item(e.key, 0));
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(6)),
                          child: Text('×${e.value}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF444444))),
                        ),
                        const SizedBox(width: 12),
                        Text('₹${(item.price * e.value).toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE87722))),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 10),
                const Divider(color: Color(0xFFEEEEEE)),
                const SizedBox(height: 8),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                    Text('₹${total.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                  ],
                ),
                const SizedBox(height: 20),

                // Payment mode
                const Text('Payment Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF888888))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheet(() => selectedPayment = 'Cash'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selectedPayment == 'Cash' ? const Color(0xFF27AE60) : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selectedPayment == 'Cash' ? const Color(0xFF27AE60) : const Color(0xFFE0E0E0),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.payments_rounded, size: 26,
                                  color: selectedPayment == 'Cash' ? Colors.white : const Color(0xFF888888)),
                              const SizedBox(height: 6),
                              Text('Cash', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                  color: selectedPayment == 'Cash' ? Colors.white : const Color(0xFF555555))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheet(() => selectedPayment = 'Online'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selectedPayment == 'Online' ? const Color(0xFF2F80ED) : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selectedPayment == 'Online' ? const Color(0xFF2F80ED) : const Color(0xFFE0E0E0),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.qr_code_scanner_rounded, size: 26,
                                  color: selectedPayment == 'Online' ? Colors.white : const Color(0xFF888888)),
                              const SizedBox(height: 6),
                              Text('Online', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                  color: selectedPayment == 'Online' ? Colors.white : const Color(0xFF555555))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Confirm button
                GestureDetector(
                  onTap: () {
                    // Save to orderTable for summary reporting
                    for (final e in cartSnapshot.entries) {
                      final item = menu.firstWhere((m) => m.name == e.key, orElse: () => Item(e.key, 0));
                      orderTable.orders.add(Order(item, e.value));
                    }

                    // Save individual bill history before completeBill clears orders
                    final billItems = cartSnapshot.entries.map((e) {
                      final item = menu.firstWhere((m) => m.name == e.key, orElse: () => Item(e.key, 0));
                      return {'name': e.key, 'qty': e.value, 'price': item.price, 'lineTotal': item.price * e.value};
                    }).toList();
                    orderBillHistory.add({
                      'billNo': orderBillHistory.length + 1,
                      'items': billItems,
                      'total': total,
                      'payment': selectedPayment,
                      'time': DateTime.now(),
                    });

                    orderTable.completeBill();

                    setState(() {
                      _orderCart.clear();
                      _orderCount++;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text('Order bill done — $selectedPayment ₹${total.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        backgroundColor: selectedPayment == 'Cash' ? const Color(0xFF27AE60) : const Color(0xFF2F80ED),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity, height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: selectedPayment == 'Cash'
                            ? [const Color(0xFF2ECC71), const Color(0xFF27AE60)]
                            : [const Color(0xFF56CCF2), const Color(0xFF2F80ED)],
                        begin: Alignment.centerLeft, end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (selectedPayment == 'Cash' ? const Color(0xFF27AE60) : const Color(0xFF2F80ED)).withValues(alpha: 0.38),
                          blurRadius: 14, offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(selectedPayment == 'Cash' ? Icons.payments_rounded : Icons.qr_code_scanner_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text('Confirm $selectedPayment — ₹${total.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                          ],
                        ),
                        if (_orderCount > 0)
                          Positioned(
                            right: 14,
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${_orderCount + 1}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: selectedPayment == 'Cash' ? const Color(0xFF27AE60) : const Color(0xFF2F80ED),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // ── Tables Page ──────────────────────────────────────────────────────────
  Widget _buildTablesPage(int activeTables) {
    // Responsive aspect ratio: taller cards on small phones so the sub-table
    // chips + active badge never overflow on Redmi / Realme / Vivo / Oppo etc.
    final double w = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Text("Tables", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: thTxtMain, letterSpacing: 0.5)),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: tables.length,
            // NOTE: `const` removed here because childAspectRatio now reads MediaQuery.
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: w < 380 ? 0.72 : 0.82,
            ),
            itemBuilder: (context, index) {
              final table = tables[index];
              final subs = subTables[table.tableNo] ?? [];
              final bool isActive = table.isOccupied || subs.any((s) => s.isOccupied);
              final theme = _tableThemes[index % _tableThemes.length];
              return _TableCard(
                table: table, subTables: subs, isActive: isActive, tableIndex: index,
                onTap: () => _showTableSheet(context, table, subs, theme, index),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showTableSheet(BuildContext context, TableData table, List<TableData> subs, _TableTheme theme, int index) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(color: thCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            Row(children: [
              Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: theme.activeIconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.table_restaurant_rounded, color: theme.activeIconColor, size: 22)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Table " + table.tableLabel, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: thTxtMain)),
                Text("Choose how to use this table", style: TextStyle(fontSize: 12, color: thTxtSub)),
              ]),
            ]),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(table: table, gradientColors: theme.gradientColors)));
                refresh();
              },
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: theme.gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.activeIconColor.withValues(alpha: 0.30), width: 1.5),
                ),
                child: Row(children: [
                  Icon(Icons.people_rounded, color: theme.activeIconColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Table " + table.tableLabel + " — Group Order", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: theme.activeIconColor)),
                    const Text("Everyone orders together", style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                  ])),
                  if (table.isOccupied) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: theme.activeIconColor, borderRadius: BorderRadius.circular(10)),
                    child: const Text("● Active", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded, color: theme.activeIconColor),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              const Expanded(child: Divider()),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text("or split by person", style: TextStyle(fontSize: 12, color: thTxtSub, fontWeight: FontWeight.w500))),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: 16),
            Row(
              children: subs.map((sub) {
                final bool subActive = sub.isOccupied;
                return Expanded(child: Padding(
                  padding: EdgeInsets.only(right: sub == subs.last ? 0 : 12),
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(table: sub, gradientColors: theme.gradientColors)));
                      refresh();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: subActive ? theme.activeIconColor.withValues(alpha: 0.12) : thCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: subActive ? theme.activeIconColor : Colors.grey.shade300, width: subActive ? 1.8 : 1.2),
                      ),
                      child: Column(children: [
                        Icon(Icons.person_rounded, color: subActive ? theme.activeIconColor : thTxtSub, size: 24),
                        const SizedBox(height: 6),
                        Text("Table " + sub.tableLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: subActive ? theme.activeIconColor : thTxtMain)),
                        const SizedBox(height: 4),
                        subActive
                            ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: theme.activeIconColor, borderRadius: BorderRadius.circular(8)),
                            child: Text("₹" + sub.total.toStringAsFixed(0), style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)))
                            : Text("Empty", style: TextStyle(fontSize: 11, color: thTxtSub)),
                      ]),
                    ),
                  ),
                ));
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }


  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(int activeTables) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: const Color(0xFFE87722).withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset('assets/logo.png', width: 46, height: 46, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hotelName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A), letterSpacing: 1.4),
                ),
                const SizedBox(height: 2),
                Text(
                  '$activeTables table${activeTables != 1 ? 's' : ''} active',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF888888), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: activeTables > 0 ? const Color(0xFFD4F5E6) : const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: activeTables > 0 ? const Color(0xFF2ECC71) : const Color(0xFFBBBBBB),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  activeTables > 0 ? 'Live' : 'Idle',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: activeTables > 0 ? const Color(0xFF27AE60) : const Color(0xFF888888)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _showSettingsPasswordDialog(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: thCard,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: const Color(0xFFE87722).withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 3))],
                border: Border.all(color: const Color(0xFFE87722).withValues(alpha: 0.35), width: 1.2),
              ),
              child: const Icon(Icons.settings_rounded, size: 20, color: Color(0xFFE87722)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ───────────────────────────────────────────────────────────
  Widget _buildBottomBar(double total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.09), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Column(
        children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: const Color(0xFFD8D8D8), borderRadius: BorderRadius.circular(2)),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Today's Total", style: TextStyle(fontSize: 12, color: Color(0xFF888888), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text('₹${total.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A), height: 1)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SummaryScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB347), Color(0xFFE87722), Color(0xFFFF4500)],
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: const Color(0xFFE87722).withValues(alpha: 0.42), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bar_chart_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Sales Report', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Order Menu Card ───────────────────────────────────────────────────────
class _OrderMenuCard extends StatelessWidget {
  final Item item;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _OrderMenuCard({required this.item, required this.qty, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final bool inCart = qty > 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: inCart ? const Color(0xFFE87722).withValues(alpha: 0.5) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: _buildImage(item.image),
            ),
          ),
          // Name + Price + buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                      child: Text('₹${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE87722))),
                    ),
                    if (!inCart)
                      GestureDetector(
                        onTap: onAdd,
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE87722),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        ),
                      )
                    else
                      Row(
                        children: [
                          GestureDetector(
                            onTap: onRemove,
                            child: Container(
                              width: 26, height: 26,
                              decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(7)),
                              child: const Icon(Icons.remove_rounded, size: 15, color: Colors.black87),
                            ),
                          ),
                          SizedBox(
                            width: 24,
                            child: Text('$qty', textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                          ),
                          GestureDetector(
                            onTap: onAdd,
                            child: Container(
                              width: 26, height: 26,
                              decoration: BoxDecoration(color: const Color(0xFFE87722), borderRadius: BorderRadius.circular(7)),
                              child: const Icon(Icons.add_rounded, size: 15, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String? path) {
    if (path == null) {
      return Container(
        color: const Color(0xFFF5F5F5),
        child: const Center(child: Icon(Icons.fastfood_rounded, color: Color(0xFFCCCCCC), size: 40)),
      );
    }
    if (path.startsWith('assets/')) return Image.asset(path, fit: BoxFit.cover, width: double.infinity);
    return Image.file(File(path), fit: BoxFit.cover, width: double.infinity);
  }
}

// ── Table Theme ────────────────────────────────────────────────────────────
class _TableTheme {
  final List<Color> gradientColors;
  final Color iconColor;
  final Color activeIconColor;
  final Color amountColor;
  const _TableTheme({required this.gradientColors, required this.iconColor, required this.activeIconColor, required this.amountColor});
}

const List<_TableTheme> _tableThemes = [
  _TableTheme(gradientColors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)], iconColor: Color(0xFF9575CD), activeIconColor: Color(0xFF5E35B1), amountColor: Color(0xFF5E35B1)),
  _TableTheme(gradientColors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)], iconColor: Color(0xFF7986CB), activeIconColor: Color(0xFF303F9F), amountColor: Color(0xFF303F9F)),
  _TableTheme(gradientColors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)], iconColor: Color(0xFF64B5F6), activeIconColor: Color(0xFF1565C0), amountColor: Color(0xFF1565C0)),
  _TableTheme(gradientColors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)], iconColor: Color(0xFF66BB6A), activeIconColor: Color(0xFF2E7D32), amountColor: Color(0xFF2E7D32)),
  _TableTheme(gradientColors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)], iconColor: Color(0xFFF48FB1), activeIconColor: Color(0xFFAD1457), amountColor: Color(0xFFAD1457)),
  _TableTheme(gradientColors: [Color(0xFFFFF3E0), Color(0xFFFFCC80)], iconColor: Color(0xFFFFB74D), activeIconColor: Color(0xFFE65100), amountColor: Color(0xFFE65100)),
  _TableTheme(gradientColors: [Color(0xFFFFEBEE), Color(0xFFFFCDD2)], iconColor: Color(0xFFE57373), activeIconColor: Color(0xFFC62828), amountColor: Color(0xFFC62828)),
  _TableTheme(gradientColors: [Color(0xFFEFEBE9), Color(0xFFD7CCC8)], iconColor: Color(0xFFA1887F), activeIconColor: Color(0xFF4E342E), amountColor: Color(0xFF4E342E)),
];

// ── Table Card ─────────────────────────────────────────────────────────────
class _TableCard extends StatelessWidget {
  final TableData table;
  final List<TableData> subTables;
  final bool isActive;
  final int tableIndex;
  final VoidCallback onTap;

  const _TableCard({required this.table, required this.subTables, required this.isActive, required this.tableIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = _tableThemes[tableIndex % _tableThemes.length];
    final double totalRevenue = table.dailyTotal + subTables.fold<double>(0, (s, t) => s + t.dailyTotal);
    final int totalUsage = table.usageCount + subTables.fold<int>(0, (s, t) => s + t.usageCount);
    final activeSubCount = subTables.where((s) => s.isOccupied).length;

    // Responsive sizing for small Android devices (Redmi / Realme / Vivo / Oppo etc.)
    final double w = MediaQuery.of(context).size.width;
    final bool isSmall = w < 380;
    final double pad = isSmall ? 12 : 16;
    final double iconBox = isSmall ? 46 : 54;
    final double iconSize = isSmall ? 24 : 28;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: theme.gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive ? theme.activeIconColor.withValues(alpha: 0.45) : theme.activeIconColor.withValues(alpha: 0.20),
            width: 1.5,
          ),
          boxShadow: [BoxShadow(
            color: isActive ? theme.activeIconColor.withValues(alpha: 0.25) : theme.iconColor.withValues(alpha: 0.22),
            blurRadius: isActive ? 20 : 12, offset: const Offset(0, 4),
          )],
        ),
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            // mainAxisSize.min -> column only takes the height it needs (no vertical overflow)
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: iconBox, height: iconBox,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(16)),
                  child: Icon(Icons.table_restaurant_rounded, size: iconSize, color: isActive ? theme.activeIconColor : theme.iconColor.withValues(alpha: 0.90))),
              SizedBox(height: isSmall ? 8 : 10),

              // FittedBox keeps the title from forcing the card wider
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text("Table " + table.tableLabel,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
              ),
              const SizedBox(height: 5),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.78), borderRadius: BorderRadius.circular(20)),
                child: Text("₹" + totalRevenue.toStringAsFixed(0), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isActive ? theme.amountColor : const Color(0xFF999999))),
              ),
              const SizedBox(height: 5),

              Text("Used " + totalUsage.toString() + "×", style: const TextStyle(fontSize: 11, color: Color(0xFF777777), fontWeight: FontWeight.w500)),
              SizedBox(height: isSmall ? 6 : 8),

              // Wrap -> sub-table chips (1A, 1B…) flow to the next line instead of
              // overflowing horizontally outside the card.
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: subTables.map((sub) {
                  final bool subOccupied = sub.isOccupied;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: subOccupied ? theme.activeIconColor : Colors.white.withValues(alpha: 0.60),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: subOccupied ? theme.activeIconColor : theme.iconColor.withValues(alpha: 0.30), width: 1),
                    ),
                    child: Text(sub.tableLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: subOccupied ? Colors.white : theme.iconColor)),
                  );
                }).toList(),
              ),

              if (isActive) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: theme.activeIconColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(activeSubCount > 0 ? "● $activeSubCount split active" : "● Occupied",
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


class EditMenuScreen extends StatefulWidget {
  final List<Color> gradientColors;
  final Color accentColor;

  const EditMenuScreen({super.key, required this.gradientColors, required this.accentColor});

  @override
  State<EditMenuScreen> createState() => _EditMenuScreenState();
}

class _EditMenuScreenState extends State<EditMenuScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedImagePath;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final saved = await File(picked.path).copy(p.join(appDir.path, fileName));
    setState(() => _selectedImagePath = saved.path);
  }

  void _showImageSourceSheet({Function(String)? onPicked}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFFE87722))),
              title: const Text('Gallery-லிருந்து தேர்வு', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                if (onPicked != null) {
                  final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (picked != null) {
                    final appDir = await getApplicationDocumentsDirectory();
                    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
                    final saved = await File(picked.path).copy(p.join(appDir.path, fileName));
                    onPicked(saved.path);
                  }
                } else { _pickImage(ImageSource.gallery); }
              },
            ),
            ListTile(
              leading: Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2ECC71))),
              title: const Text('Camera-ல் எடு', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                if (onPicked != null) {
                  final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                  if (picked != null) {
                    final appDir = await getApplicationDocumentsDirectory();
                    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
                    final saved = await File(picked.path).copy(p.join(appDir.path, fileName));
                    onPicked(saved.path);
                  }
                } else { _pickImage(ImageSource.camera); }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    if (name.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('❌ பெயர் மற்றும் விலை சரியாக இல்லை!'),
        backgroundColor: Color(0xFFE74C3C), behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() {
      menu.add(Item(name, price, image: _selectedImagePath));
      _nameController.clear();
      _priceController.clear();
      _selectedImagePath = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ $name சேர்க்கப்பட்டது!'),
      backgroundColor: const Color(0xFF2ECC71), behavior: SnackBarBehavior.floating,
    ));
  }

  void _deleteItem(int index) {
    final name = menu[index].name;
    setState(() => menu.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🗑️ $name நீக்கப்பட்டது!'),
      backgroundColor: const Color(0xFFE74C3C), behavior: SnackBarBehavior.floating,
    ));
  }

  void _editItem(int index) {
    final item = menu[index];
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(text: item.price.toString());
    String? editImagePath = item.image;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: thCard,
          title: const Text('Item திருத்து', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (_) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 12),
                          ListTile(
                            leading: Container(width: 40, height: 40,
                                decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.photo_library_rounded, color: Color(0xFFE87722))),
                            title: const Text('Gallery-லிருந்து தேர்வு', style: TextStyle(fontWeight: FontWeight.w600)),
                            onTap: () async {
                              Navigator.pop(context);
                              final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                              if (picked != null) {
                                final appDir = await getApplicationDocumentsDirectory();
                                final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
                                final saved = await File(picked.path).copy(p.join(appDir.path, fileName));
                                setDialogState(() => editImagePath = saved.path);
                                setState(() => menu[index].image = saved.path);
                              }
                            },
                          ),
                          ListTile(
                            leading: Container(width: 40, height: 40,
                                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2ECC71))),
                            title: const Text('Camera-ல் எடு', style: TextStyle(fontWeight: FontWeight.w600)),
                            onTap: () async {
                              Navigator.pop(context);
                              final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                              if (picked != null) {
                                final appDir = await getApplicationDocumentsDirectory();
                                final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
                                final saved = await File(picked.path).copy(p.join(appDir.path, fileName));
                                setDialogState(() => editImagePath = saved.path);
                                setState(() => menu[index].image = saved.path);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 80, width: double.infinity,
                  decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8E8E8))),
                  child: _buildImageWidget(editImagePath),
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: _inputDecoration('Item பெயர்')),
              const SizedBox(height: 10),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: _inputDecoration('விலை')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(0xFF888888)))),
            GestureDetector(
              onTap: () {
                final newName = nameCtrl.text.trim();
                final newPrice = double.tryParse(priceCtrl.text.trim());
                if (newName.isNotEmpty && newPrice != null) {
                  setState(() { menu[index] = Item(newName, newPrice, image: menu[index].image); });
                  Navigator.pop(context);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFB347), Color(0xFFE87722)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String? path) {
    if (path == null) {
      return const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_a_photo_rounded, color: Color(0xFFE87722), size: 28),
        SizedBox(height: 4),
        Text('Image', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
      ]);
    }
    if (path.startsWith('assets/')) {
      return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(path, fit: BoxFit.cover, width: double.infinity));
    }
    return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(path), fit: BoxFit.cover, width: double.infinity));
  }

  Widget _buildListImage(String? path) {
    if (path == null) {
      return Container(width: 48, height: 48,
          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.fastfood_rounded, color: Color(0xFFCCCCCC), size: 24));
    }
    if (path.startsWith('assets/')) {
      return ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset(path, width: 48, height: 48, fit: BoxFit.cover));
    }
    return ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(path), width: 48, height: 48, fit: BoxFit.cover));
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint, filled: true, fillColor: thInput,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1.2)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE87722), width: 1.8)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: thBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)]),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Edit Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                    Text('Add, edit or remove items', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                  ]),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: const Color(0xFFE87722).withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(width: 32, height: 32,
                                decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.add_rounded, color: Color(0xFFE87722), size: 18)),
                            const SizedBox(width: 10),
                            const Text('Add New Item', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          ]),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () => _showImageSourceSheet(),
                            child: Container(
                              height: 100, width: double.infinity,
                              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8E8E8))),
                              child: _buildImageWidget(_selectedImagePath),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(controller: _nameController, decoration: _inputDecoration('Item Name')),
                          const SizedBox(height: 10),
                          TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: _inputDecoration('Price')),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: _addItem,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFFFFB347), Color(0xFFE87722)]),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.add_rounded, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text('Add to Menu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                                ]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      const Text('Current Menu', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFE87722), borderRadius: BorderRadius.circular(20)),
                        child: Text('${menu.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    ...List.generate(menu.length, (index) {
                      final item = menu[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(children: [
                          _buildListImage(item.image),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text('₹${item.price}', style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
                          ])),
                          GestureDetector(
                            onTap: () => _editItem(index),
                            child: Container(width: 36, height: 36,
                                decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFFE87722))),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _deleteItem(index),
                            child: Container(width: 36, height: 36,
                                decoration: BoxDecoration(color: const Color(0xFFFFEBEB), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.delete_rounded, size: 16, color: Colors.redAccent)),
                          ),
                        ]),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}