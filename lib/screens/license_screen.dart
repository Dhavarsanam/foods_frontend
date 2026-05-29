// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'login_screen.dart';
// import '../widgets/footer.dart';
//
// // ══════════════════════════════════════════════════════════════════
// //  Valid License Keys — நீங்க இங்க keys add/remove பண்ணலாம்
// //  Format: 'CLIENT_NAME': 'KEY'
// // ══════════════════════════════════════════════════════════════════
// const Map<String, String> _validLicenses = {
//   'GSS-HOTEL-2025-AAA1': 'Client 1',
//   'GSS-HOTEL-2025-BBB2': 'Client 2',
//   'GSS-HOTEL-2025-CCC3': 'Client 3',
//   'GSS-HOTEL-2025-DDD4': 'Client 4',
//   'GSS-HOTEL-2025-EEE5': 'Client 5',
// };
//
// class LicenseScreen extends StatefulWidget {
//   const LicenseScreen({super.key});
//
//   @override
//   State<LicenseScreen> createState() => _LicenseScreenState();
// }
//
// class _LicenseScreenState extends State<LicenseScreen>
//     with TickerProviderStateMixin {
//   final _keyController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;
//   bool _isError = false;
//   String _errorMsg = '';
//
//   late AnimationController _fadeController;
//   late Animation<double> _fadeAnim;
//   late Animation<Offset> _slideAnim;
//
//   @override
//   void initState() {
//     super.initState();
//     _fadeController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1000),
//     );
//     _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
//     _slideAnim = Tween<Offset>(
//       begin: const Offset(0, 0.1),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
//
//     _fadeController.forward();
//   }
//
//   @override
//   void dispose() {
//     _fadeController.dispose();
//     _keyController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _onActivate() async {
//     if (!(_formKey.currentState?.validate() ?? false)) return;
//
//     setState(() {
//       _isLoading = true;
//       _isError = false;
//     });
//
//     await Future.delayed(const Duration(milliseconds: 800));
//
//     final enteredKey = _keyController.text.trim().toUpperCase();
//
//     if (_validLicenses.containsKey(enteredKey)) {
//       // ✅ Valid key — save பண்ணி login page-க்கு போ
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('licenseKey', enteredKey);
//       await prefs.setString('licenseClient', _validLicenses[enteredKey]!);
//
//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const LoginScreen()),
//       );
//     } else {
//       // ❌ Invalid key
//       if (!mounted) return;
//       setState(() {
//         _isLoading = false;
//         _isError = true;
//         _errorMsg = 'Invalid License Key! Gateway Software Solutions-ஐ தொடர்பு கொள்ளவும்.';
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F6F3),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
//                 child: FadeTransition(
//                   opacity: _fadeAnim,
//                   child: SlideTransition(
//                     position: _slideAnim,
//                     child: Column(
//                       children: [
//                         // ── GSS Branding ─────────────────────────────────
//                         Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFFE87722).withOpacity(0.07),
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(
//                               color: const Color(0xFFE87722).withOpacity(0.18),
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Image.asset(
//                                 'assets/gss_logo.png',
//                                 width: 26,
//                                 height: 26,
//                                 fit: BoxFit.contain,
//                               ),
//                               const SizedBox(width: 9),
//                               const Text(
//                                 'Gateway Software Solutions',
//                                 style: TextStyle(
//                                   fontSize: 12.5,
//                                   fontWeight: FontWeight.w700,
//                                   color: Color(0xFFE87722),
//                                   letterSpacing: 0.3,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         const SizedBox(height: 40),
//
//                         // ── Lock icon ─────────────────────────────────────
//                         Container(
//                           width: 100,
//                           height: 100,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(28),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: const Color(0xFFE87722).withOpacity(0.18),
//                                 blurRadius: 30,
//                                 offset: const Offset(0, 10),
//                               ),
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.06),
//                                 blurRadius: 16,
//                                 offset: const Offset(0, 4),
//                               ),
//                             ],
//                           ),
//                           child: const Center(
//                             child: Icon(
//                               Icons.vpn_key_rounded,
//                               size: 48,
//                               color: Color(0xFFE87722),
//                             ),
//                           ),
//                         ),
//
//                         const SizedBox(height: 24),
//
//                         const Text(
//                           'App Activation',
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.w900,
//                             color: Color(0xFF1A1A1A),
//                             letterSpacing: 0.5,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         const Text(
//                           'உங்கள் License Key-ஐ உள்ளிடவும்',
//                           style: TextStyle(
//                             fontSize: 13,
//                             color: Color(0xFF999999),
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//
//                         const SizedBox(height: 40),
//
//                         // ── Form card ─────────────────────────────────────
//                         Container(
//                           padding: const EdgeInsets.all(28),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(28),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.07),
//                                 blurRadius: 30,
//                                 offset: const Offset(0, 8),
//                               ),
//                             ],
//                           ),
//                           child: Form(
//                             key: _formKey,
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 const Text(
//                                   'License Key',
//                                   style: TextStyle(
//                                     fontSize: 13,
//                                     fontWeight: FontWeight.w600,
//                                     color: Color(0xFF666666),
//                                   ),
//                                 ),
//                                 const SizedBox(height: 10),
//
//                                 // Key input field
//                                 TextFormField(
//                                   controller: _keyController,
//                                   keyboardType: TextInputType.text,
//                                   textCapitalization: TextCapitalization.characters,
//                                   inputFormatters: [
//                                     FilteringTextInputFormatter.allow(
//                                       RegExp(r'[A-Za-z0-9\-]'),
//                                     ),
//                                   ],
//                                   style: const TextStyle(
//                                     fontSize: 15,
//                                     fontWeight: FontWeight.w700,
//                                     color: Color(0xFF1A1A1A),
//                                     letterSpacing: 1.5,
//                                   ),
//                                   decoration: InputDecoration(
//                                     hintText: 'GSS-HOTEL-2025-XXXX',
//                                     hintStyle: const TextStyle(
//                                       color: Color(0xFFCCCCCC),
//                                       fontWeight: FontWeight.w400,
//                                       letterSpacing: 1,
//                                     ),
//                                     prefixIcon: const Icon(
//                                       Icons.key_rounded,
//                                       color: Color(0xFFE87722),
//                                       size: 22,
//                                     ),
//                                     filled: true,
//                                     fillColor: const Color(0xFFF5F5F5),
//                                     contentPadding: const EdgeInsets.symmetric(
//                                         horizontal: 16, vertical: 16),
//                                     enabledBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(14),
//                                       borderSide: const BorderSide(
//                                           color: Color(0xFFE8E8E8), width: 1.5),
//                                     ),
//                                     focusedBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(14),
//                                       borderSide: const BorderSide(
//                                           color: Color(0xFFE87722), width: 2),
//                                     ),
//                                     errorBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(14),
//                                       borderSide: const BorderSide(
//                                           color: Color(0xFFE53935), width: 1.5),
//                                     ),
//                                     focusedErrorBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(14),
//                                       borderSide: const BorderSide(
//                                           color: Color(0xFFE53935), width: 2),
//                                     ),
//                                   ),
//                                   validator: (v) {
//                                     if (v == null || v.trim().isEmpty) {
//                                       return 'License key உள்ளிடவும்';
//                                     }
//                                     return null;
//                                   },
//                                 ),
//
//                                 // Error message
//                                 if (_isError) ...[
//                                   const SizedBox(height: 14),
//                                   Container(
//                                     padding: const EdgeInsets.all(12),
//                                     decoration: BoxDecoration(
//                                       color: const Color(0xFFFFEBEB),
//                                       borderRadius: BorderRadius.circular(10),
//                                       border: Border.all(
//                                           color: const Color(0xFFFFCDD2)),
//                                     ),
//                                     child: Row(
//                                       children: [
//                                         const Icon(Icons.error_outline_rounded,
//                                             color: Color(0xFFE53935), size: 18),
//                                         const SizedBox(width: 8),
//                                         Expanded(
//                                           child: Text(
//                                             _errorMsg,
//                                             style: const TextStyle(
//                                               color: Color(0xFFE53935),
//                                               fontSize: 12.5,
//                                               fontWeight: FontWeight.w500,
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//
//                                 const SizedBox(height: 24),
//
//                                 // Activate button
//                                 GestureDetector(
//                                   onTap: _isLoading ? null : _onActivate,
//                                   child: Container(
//                                     width: double.infinity,
//                                     height: 54,
//                                     decoration: BoxDecoration(
//                                       gradient: const LinearGradient(
//                                         colors: [
//                                           Color(0xFFFFB347),
//                                           Color(0xFFE87722),
//                                           Color(0xFFFF4500),
//                                         ],
//                                         begin: Alignment.centerLeft,
//                                         end: Alignment.centerRight,
//                                       ),
//                                       borderRadius: BorderRadius.circular(16),
//                                       boxShadow: [
//                                         BoxShadow(
//                                           color: const Color(0xFFE87722)
//                                               .withOpacity(0.35),
//                                           blurRadius: 18,
//                                           offset: const Offset(0, 6),
//                                         ),
//                                       ],
//                                     ),
//                                     child: Row(
//                                       mainAxisAlignment: MainAxisAlignment.center,
//                                       children: [
//                                         if (_isLoading)
//                                           const SizedBox(
//                                             width: 20,
//                                             height: 20,
//                                             child: CircularProgressIndicator(
//                                                 strokeWidth: 2,
//                                                 color: Colors.white),
//                                           )
//                                         else ...[
//                                           const Icon(Icons.verified_rounded,
//                                               color: Colors.white, size: 20),
//                                           const SizedBox(width: 8),
//                                         ],
//                                         const SizedBox(width: 4),
//                                         Text(
//                                           _isLoading ? 'Verifying...' : 'Activate App',
//                                           style: const TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 15,
//                                             fontWeight: FontWeight.w700,
//                                             letterSpacing: 0.8,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//
//                                 const SizedBox(height: 20),
//
//                                 // Contact info
//                                 Center(
//                                   child: Column(
//                                     children: [
//                                       const Text(
//                                         'License Key இல்லையா?',
//                                         style: TextStyle(
//                                           fontSize: 12.5,
//                                           color: Color(0xFF999999),
//                                         ),
//                                       ),
//                                       const SizedBox(height: 4),
//                                       const Text(
//                                         'Gateway Software Solutions-ஐ தொடர்பு கொள்ளவும்',
//                                         textAlign: TextAlign.center,
//                                         style: TextStyle(
//                                           fontSize: 12,
//                                           color: Color(0xFFE87722),
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             const AppFooter(),
//           ],
//         ),
//       ),
//     );
//   }
// }
