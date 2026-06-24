import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../widgets/footer.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {

  int _step = 0;
  bool _serverReady = false;
  String _serverStatus = 'Server starting up...';

  final _hotelNameController = TextEditingController();
  final _ownerNameController  = TextEditingController();
  final _mobileController     = TextEditingController();
  final _otpController        = TextEditingController();

  final _formKey    = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  bool   _isLoading     = false;
  int    _resendSeconds = 0;
  Timer? _resendTimer;

  late AnimationController _mainFadeController;
  late AnimationController _stepSlideController;
  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _stepFade;
  late Animation<Offset> _stepSlide;

  @override
  void initState() {
    super.initState();

    _mainFadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _logoFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _mainFadeController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(CurvedAnimation(
        parent: _mainFadeController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _cardFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _mainFadeController, curve: const Interval(0.35, 0.85, curve: Curves.easeOut)));
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(CurvedAnimation(
        parent: _mainFadeController, curve: const Interval(0.35, 0.85, curve: Curves.easeOut)));

    _stepSlideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _stepFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _stepSlideController, curve: Curves.easeOut));
    _stepSlide = Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: _stepSlideController, curve: Curves.easeOut));

    _mainFadeController.forward();
    _stepSlideController.forward();

    _wakeServer(); // ✅ Server wake up
  }

  // ── Wake server with retry ─────────────────────────────────────────────────
  Future<void> _wakeServer() async {
    setState(() { _serverReady = false; _serverStatus = '⏳ Server starting...'; });

    for (int attempt = 1; attempt <= 5; attempt++) {
      try {
        if (mounted) setState(() => _serverStatus = '⏳ Connecting... ($attempt/5)');

        final res = await http
            .get(Uri.parse('https://foods-backend-5o8e.onrender.com'))
            .timeout(const Duration(seconds: 45));

        if (res.statusCode == 200) {
          if (mounted) setState(() { _serverReady = true; _serverStatus = ''; });
          print('✅ Server ready on attempt $attempt');
          return;
        }
      } catch (e) {
        print('Attempt $attempt failed: $e');
        if (attempt < 5) await Future.delayed(const Duration(seconds: 3));
      }
    }

    // After all attempts — let user try anyway
    if (mounted) setState(() { _serverReady = true; _serverStatus = ''; });
  }

  @override
  void dispose() {
    _mainFadeController.dispose();
    _stepSlideController.dispose();
    _hotelNameController.dispose();
    _ownerNameController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() { if (_resendSeconds > 0) _resendSeconds--; else t.cancel(); });
    });
  }

  void _animateStep() => _stepSlideController..reset()..forward();

  Future<void> _onGenerateOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_serverReady) {
      ScaffoldMessenger.of(context).showSnackBar(_snackBar(
          '⏳ Server இன்னும் start ஆகல. சிறிது நேரம் wait பண்ணவும்...', isError: true));
      _wakeServer();
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService.sendOtp(_mobileController.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() => _step = 1);
      _animateStep();
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(_snackBar('OTP admin email-க்கு அனுப்பப்பட்டது ✅'));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(_snackBar(
          result['message'] ?? 'OTP அனுப்ப முடியவில்லை', isError: true));
    }
  }

  Future<void> _onResendOtp() async {
    if (_resendSeconds > 0) return;
    setState(() => _isLoading = true);
    final result = await ApiService.sendOtp(_mobileController.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result['success'] == true) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(_snackBar('OTP மீண்டும் அனுப்பப்பட்டது'));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(_snackBar(
          result['message'] ?? 'OTP அனுப்ப முடியவில்லை', isError: true));
    }
  }

  Future<void> _onVerifyOtp() async {
    if (!(_otpFormKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final result = await ApiService.verifyOtp(
        _mobileController.text.trim(), _otpController.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('hotelName', _hotelNameController.text.trim());
      await prefs.setString('ownerName', _ownerNameController.text.trim());
      await prefs.setString('mobile', _mobileController.text.trim());
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(_snackBar(
          result['message'] ?? 'தவறான OTP. மீண்டும் முயற்சிக்கவும்.', isError: true));
    }
  }

  SnackBar _snackBar(String msg, {bool isError = false}) => SnackBar(
    content: Text(msg),
    backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFFE87722),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  // ── Server connecting banner ───────────────────────────────────────────────
  Widget _buildServerBanner() {
    if (_serverReady) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE87722).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE87722))),
          const SizedBox(width: 10),
          Expanded(child: Text(_serverStatus,
              style: const TextStyle(fontSize: 12, color: Color(0xFFE87722), fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildBrandingHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE87722).withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE87722).withOpacity(0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/gss_logo.png', width: 26, height: 26, fit: BoxFit.contain),
          const SizedBox(width: 9),
          const Text('Gateway Software Solutions',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700,
                  color: Color(0xFFE87722), letterSpacing: 0.3)),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    int? maxLength,
    String? Function(String?)? validator,
    TextAlign textAlign = TextAlign.start,
    TextStyle? style,
  }) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType,
      inputFormatters: formatters, maxLength: maxLength,
      validator: validator, textAlign: textAlign,
      style: style ?? const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon, color: const Color(0xFFE87722), size: 22),
        counterText: '',
        filled: true, fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE87722), width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 2)),
      ),
    );
  }

  Widget _gradientButton({required String label, required VoidCallback? onTap, IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFFB347), Color(0xFFE87722), Color(0xFFFF4500)],
              begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFFE87722).withOpacity(0.35),
              blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            else if (!_serverReady)
              const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            else if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8),
              ],
            const SizedBox(width: 4),
            Text(
              _isLoading ? 'Please wait...' : (!_serverReady ? 'Connecting...' : label),
              style: const TextStyle(color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w700, letterSpacing: 0.8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accentLine({required bool toRight}) => Container(
    width: 24, height: 1.5,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: toRight
          ? [const Color(0xFFE87722), Colors.transparent]
          : [Colors.transparent, const Color(0xFFE87722)]),
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _buildDetailsForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildServerBanner(), // ✅ Server status banner
          const Text('Welcome 👋',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          const Text('உங்கள் விவரங்களை உள்ளிடவும்',
              style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
          const SizedBox(height: 24),
          _inputField(controller: _hotelNameController, hint: 'Hotel Name',
              icon: Icons.storefront_rounded,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Hotel name உள்ளிடவும்' : null),
          const SizedBox(height: 14),
          _inputField(controller: _ownerNameController, hint: 'Owner Name',
              icon: Icons.person_rounded,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Owner name உள்ளிடவும்' : null),
          const SizedBox(height: 14),
          _inputField(controller: _mobileController, hint: 'Mobile Number',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone, maxLength: 10,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Mobile number உள்ளிடவும்';
                if (v.trim().length != 10) return 'சரியான 10 இலக்க number உள்ளிடவும்';
                return null;
              }),
          const SizedBox(height: 28),
          _gradientButton(
            label: 'Generate OTP', icon: Icons.sms_rounded,
            onTap: (_isLoading || !_serverReady) ? null : _onGenerateOtp,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpForm() {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () { _resendTimer?.cancel(); _otpController.clear(); setState(() => _step = 0); _animateStep(); },
            child: Row(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Color(0xFFE87722)),
              SizedBox(width: 4),
              Text('Change Details', style: TextStyle(color: Color(0xFFE87722), fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 18),
          const Text('Verify OTP 🔐',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          Text('+91 ${_mobileController.text} எண்ணிற்கு OTP admin email-க்கு அனுப்பப்பட்டது',
              style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
          const SizedBox(height: 24),
          _inputField(
              controller: _otpController, hint: '· · · · · ·',
              icon: Icons.lock_rounded,
              keyboardType: TextInputType.number, maxLength: 6,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                  letterSpacing: 10, color: Color(0xFF1A1A1A)),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'OTP உள்ளிடவும்';
                if (v.trim().length != 6) return 'OTP 6 இலக்கங்கள் இருக்க வேண்டும்';
                return null;
              }),
          const SizedBox(height: 14),
          Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('OTP வரவில்லையா? ', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
              GestureDetector(
                  onTap: _resendSeconds == 0 ? _onResendOtp : null,
                  child: Text(
                      _resendSeconds > 0 ? 'Resend in ${_resendSeconds}s' : 'Resend OTP',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: _resendSeconds > 0 ? const Color(0xFFBBBBBB) : const Color(0xFFE87722)))),
            ]),
          ),
          const SizedBox(height: 28),
          _gradientButton(label: 'Verify & Login', icon: Icons.verified_rounded,
              onTap: _isLoading ? null : _onVerifyOtp),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F3),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  children: [
                    _buildBrandingHeader(),
                    const SizedBox(height: 28),
                    FadeTransition(opacity: _logoFade, child: SlideTransition(position: _logoSlide,
                      child: Column(children: [
                        Container(width: 110, height: 110,
                            decoration: BoxDecoration(color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFFE87722).withOpacity(0.2), blurRadius: 32, offset: const Offset(0, 10)),
                                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
                                ]),
                            child: Center(child: Image.asset('assets/logo.png', width: 90, height: 90, fit: BoxFit.contain))),
                        const SizedBox(height: 20),
                        const Text('NAMMA HOTEL', textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                                color: Color(0xFF1A1A1A), letterSpacing: 2.0, height: 1.2)),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          _accentLine(toRight: false), const SizedBox(width: 10),
                          const Text('Good Taste  •  Great Moments',
                              style: TextStyle(fontSize: 12.5, color: Color(0xFF999999),
                                  fontWeight: FontWeight.w500, letterSpacing: 1.1)),
                          const SizedBox(width: 10), _accentLine(toRight: true),
                        ]),
                      ]),
                    )),
                    const SizedBox(height: 40),
                    FadeTransition(opacity: _cardFade, child: SlideTransition(position: _cardSlide,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07),
                                blurRadius: 30, offset: const Offset(0, 8))]),
                        child: FadeTransition(opacity: _stepFade, child: SlideTransition(position: _stepSlide,
                            child: _step == 0 ? _buildDetailsForm() : _buildOtpForm())),
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}