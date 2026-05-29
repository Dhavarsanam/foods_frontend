import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../data.dart';
import '../main.dart';
import '../widgets/footer.dart';
import 'login_screen.dart';
import 'edit_menu_screen.dart';

// ── Theme helpers from main.dart ─────────────────────────────────────────────
// _isDark, _bg, _card, _txtMain, _txtSub etc. — use thXxx getters from main.dart
bool get _isDark => isDarkMode;
Color get _bg        => thBg;
Color get _card      => thCard;
Color get _txtMain   => thTxtMain;
Color get _txtSub    => thTxtSub;
Color get _inputFill => thInput;
Color get _border    => thBorder;

// ══════════════════════════════════════════════════════════════════════════════
// SETTINGS SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class SettingsScreen extends StatefulWidget {
  final String adminPassword;
  final String hotelName;
  final VoidCallback onChanged;

  const SettingsScreen({
    super.key,
    required this.adminPassword,
    required this.hotelName,
    required this.onChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _adminPassword;
  late String _hotelName;
  int _tableCount = 8;
  String? _qrImagePath;
  String _selectedTheme = 'Light';

  final List<Map<String, dynamic>> _themes = [
    {'name': 'Light', 'color': const Color(0xFFE87722), 'icon': Icons.light_mode_rounded},
    {'name': 'Dark',  'color': const Color(0xFF1A1A2E), 'icon': Icons.dark_mode_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _adminPassword = widget.adminPassword;
    _hotelName = widget.hotelName;
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tableCount   = prefs.getInt('tableCount') ?? 8;
      _qrImagePath  = prefs.getString('qrImagePath');
      _selectedTheme = prefs.getString('appTheme') ?? 'Light';
    });
  }

  Future<void> _saveHotelName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hotelName', name.toUpperCase());
    setState(() => _hotelName = name.toUpperCase());
    widget.onChanged();
  }

  Future<void> _saveTableCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tableCount', count);
    rebuildTables(count);
    setState(() => _tableCount = count);
    widget.onChanged();
  }

  Future<void> _savePassword(String newPw) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adminPassword', newPw);
    setState(() => _adminPassword = newPw);
    widget.onChanged();
  }

  Future<void> _pickQrImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'qr_${DateTime.now().millisecondsSinceEpoch}.png';
    final saved = await File(picked.path).copy(p.join(appDir.path, fileName));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('qrImagePath', saved.path);
    setState(() => _qrImagePath = saved.path);
  }

  Future<void> _removeQrImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('qrImagePath');
    setState(() => _qrImagePath = null);
  }

  Future<void> _saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appTheme', theme);
    appThemeNotifier.value = theme == 'Dark' ? ThemeMode.dark : ThemeMode.light;
    setState(() => _selectedTheme = theme);
    widget.onChanged();
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showEditHotelNameDialog() {
    final ctrl = TextEditingController(text: _hotelName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _card,
        title: _dialogTitle(Icons.store_rounded, const Color(0xFFFFF3E0), const Color(0xFFE87722), 'Hotel Name'),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          style: TextStyle(color: _txtMain),
          decoration: _inputDeco('Enter hotel name'),
        ),
        actions: [_cancelBtn(), _saveBtn(() async {
          if (ctrl.text.trim().isNotEmpty) {
            await _saveHotelName(ctrl.text.trim());
            if (!mounted) return;
            Navigator.pop(context);
            _snack('✅ Hotel name updated!', const Color(0xFF2ECC71));
          }
        })],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _card,
        title: _dialogTitle(Icons.lock_reset_rounded, const Color(0xFFFFF3E0), const Color(0xFFE87722), 'Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: newCtrl, obscureText: true, keyboardType: TextInputType.number, style: TextStyle(color: _txtMain), decoration: _inputDeco('New Password')),
            const SizedBox(height: 12),
            TextField(controller: confirmCtrl, obscureText: true, keyboardType: TextInputType.number, style: TextStyle(color: _txtMain), decoration: _inputDeco('Confirm Password')),
          ],
        ),
        actions: [_cancelBtn(), _saveBtn(() async {
          if (newCtrl.text.isNotEmpty && newCtrl.text == confirmCtrl.text) {
            await _savePassword(newCtrl.text);
            if (!mounted) return;
            Navigator.pop(context);
            _snack('✅ Password changed!', const Color(0xFF2ECC71));
          } else {
            _snack('❌ Passwords do not match!', const Color(0xFFE74C3C));
          }
        })],
      ),
    );
  }

  void _showTableCountDialog() {
    int tempCount = _tableCount;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: _card,
          title: _dialogTitle(Icons.table_restaurant_rounded, const Color(0xFFE8F5E9), const Color(0xFF2ECC71), 'Number of Tables'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$tempCount tables', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _txtMain)),
              const SizedBox(height: 8),
              Slider(value: tempCount.toDouble(), min: 1, max: 20, divisions: 19, activeColor: const Color(0xFF2ECC71), label: '$tempCount',
                  onChanged: (v) => setDlg(() => tempCount = v.round())),
              const SizedBox(height: 4),
              const Text('⚠️ Changing tables will reset active orders', style: TextStyle(fontSize: 11, color: Color(0xFFE74C3C))),
            ],
          ),
          actions: [_cancelBtn(), _saveBtn(() async {
            await _saveTableCount(tempCount);
            if (!mounted) return;
            Navigator.pop(context);
            _snack('✅ Tables updated to $tempCount!', const Color(0xFF2ECC71));
          })],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _card,
        title: _dialogTitle(Icons.logout_rounded, const Color(0xFFFFEBEB), Colors.redAccent, 'Logout'),
        content: Text('Are you sure you want to logout?', style: TextStyle(fontSize: 13, color: _txtSub)),
        actions: [
          _cancelBtn(),
          GestureDetector(
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              if (!mounted) return;
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
            },
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

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, backgroundColor: color, duration: const Duration(seconds: 2)),
  );

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget _dialogTitle(IconData icon, Color bg, Color ic, String label) => Row(
    children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: ic)),
      const SizedBox(width: 10),
      Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _txtMain)),
    ],
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: _txtSub, fontSize: 14),
    filled: true, fillColor: _inputFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border, width: 1.2)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE87722), width: 1.8)),
  );

  Widget _cancelBtn() => TextButton(
    onPressed: () => Navigator.pop(context),
    child: Text('Cancel', style: TextStyle(color: _txtSub, fontWeight: FontWeight.w600)),
  );

  Widget _saveBtn(VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFB347), Color(0xFFE87722)]), borderRadius: BorderRadius.circular(10)),
      child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
    ),
  );

  Widget _tile({required IconData icon, required Color iconBg, required Color iconColor,
    required String title, required String subtitle, Widget? trailing, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _card, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: _isDark ? 0.20 : 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(13)), child: Icon(icon, size: 22, color: iconColor)),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _txtMain)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: _txtSub)),
              ],
            )),
            trailing ?? Icon(Icons.chevron_right_rounded, color: _txtSub),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
    child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _txtSub, letterSpacing: 1.2)),
  );

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeNotifier,
      builder: (context, mode, _) => Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                color: _card,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: _isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _txtMain),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _txtMain)),
                        Text('Manage your restaurant', style: TextStyle(fontSize: 12, color: _txtSub)),
                      ],
                    ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      _sectionLabel('GENERAL'),

                      _tile(
                        icon: Icons.store_rounded, iconBg: const Color(0xFFFFF3E0), iconColor: const Color(0xFFE87722),
                        title: 'Hotel Name', subtitle: _hotelName, onTap: _showEditHotelNameDialog,
                      ),
                      _tile(
                        icon: Icons.table_restaurant_rounded, iconBg: const Color(0xFFE8F5E9), iconColor: const Color(0xFF2ECC71),
                        title: 'Number of Tables', subtitle: '$_tableCount tables (each with A & B sub-tables)', onTap: _showTableCountDialog,
                      ),
                      _tile(
                        icon: Icons.restaurant_menu_rounded, iconBg: const Color(0xFFFCE4EC), iconColor: const Color(0xFFE91E63),
                        title: 'Foods', subtitle: '${menu.length} items in menu',
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const EditMenuScreen(gradientColors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)], accentColor: Color(0xFFE87722)),
                        )).then((_) => setState(() {})),
                      ),

                      _sectionLabel('PAYMENT'),

                      // QR tile
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _card, borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: _isDark ? 0.20 : 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(13)),
                                  child: const Icon(Icons.qr_code_rounded, size: 22, color: Color(0xFF2F80ED))),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Payment QR Code', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _txtMain)),
                                Text('Shown when customer pays online', style: TextStyle(fontSize: 12, color: _txtSub)),
                              ])),
                            ]),
                            const SizedBox(height: 14),
                            if (_qrImagePath != null) ...[
                              ClipRRect(borderRadius: BorderRadius.circular(12),
                                  child: Image.file(File(_qrImagePath!), height: 200, width: double.infinity, fit: BoxFit.contain)),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(child: GestureDetector(onTap: _pickQrImage,
                                    child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(12)),
                                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                          Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF2F80ED)),
                                          SizedBox(width: 6),
                                          Text('Change QR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2F80ED))),
                                        ])))),
                                const SizedBox(width: 10),
                                Expanded(child: GestureDetector(onTap: _removeQrImage,
                                    child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(color: const Color(0xFFFFEBEB), borderRadius: BorderRadius.circular(12)),
                                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                          Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                          SizedBox(width: 6),
                                          Text('Remove', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.redAccent)),
                                        ])))),
                              ]),
                            ] else
                              GestureDetector(onTap: _pickQrImage,
                                child: Container(
                                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 28),
                                  decoration: BoxDecoration(
                                    color: _isDark ? const Color(0xFF1A2233) : const Color(0xFFF0F4FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF2F80ED).withValues(alpha: 0.30), width: 1.5),
                                  ),
                                  child: Column(children: [
                                    const Icon(Icons.add_photo_alternate_rounded, size: 36, color: Color(0xFF2F80ED)),
                                    const SizedBox(height: 8),
                                    const Text('Tap to upload QR image', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2F80ED))),
                                    const SizedBox(height: 4),
                                    Text('UPI, GPay, PhonePe — any QR', style: TextStyle(fontSize: 11, color: _txtSub)),
                                  ]),
                                ),
                              ),
                          ],
                        ),
                      ),

                      _sectionLabel('APPEARANCE'),

                      // Theme tile
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _card, borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: _isDark ? 0.20 : 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(13)),
                                  child: const Icon(Icons.palette_rounded, size: 22, color: Color(0xFF9B59B6))),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('App Theme', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _txtMain)),
                                Text('Choose your color theme', style: TextStyle(fontSize: 12, color: _txtSub)),
                              ])),
                            ]),
                            const SizedBox(height: 14),
                            Row(
                              children: _themes.map((t) {
                                final bool selected = _selectedTheme == t['name'];
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => _saveTheme(t['name'] as String),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: selected ? (t['color'] as Color).withValues(alpha: 0.15) : (_isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5)),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: selected ? t['color'] as Color : Colors.transparent, width: 2),
                                      ),
                                      child: Column(children: [
                                        Icon(t['icon'] as IconData, size: 22, color: selected ? t['color'] as Color : _txtSub),
                                        const SizedBox(height: 5),
                                        Text(t['name'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                            color: selected ? t['color'] as Color : _txtSub)),
                                      ]),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      _sectionLabel('SECURITY'),

                      _tile(
                        icon: Icons.lock_reset_rounded, iconBg: const Color(0xFFFFF3E0), iconColor: const Color(0xFFE87722),
                        title: 'Change Admin Password', subtitle: 'Update your 4-digit PIN', onTap: _showChangePasswordDialog,
                      ),

                      _sectionLabel('ACCOUNT'),

                      _tile(
                        icon: Icons.logout_rounded, iconBg: const Color(0xFFFFEBEB), iconColor: Colors.redAccent,
                        title: 'Logout', subtitle: 'Sign out from this device',
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.redAccent),
                        onTap: _showLogoutDialog,
                      ),

                      const SizedBox(height: 8),
                      const AppFooter(),
                    ],
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