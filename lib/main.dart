import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash_screen.dart';

// ── Global theme notifier — listen anywhere in the app ──────────────────────
final ValueNotifier<ThemeMode> appThemeNotifier = ValueNotifier(ThemeMode.light);

// ── Convenience theme getters — use anywhere after importing main.dart ───────
bool get isDarkMode => appThemeNotifier.value == ThemeMode.dark;
Color get thBg       => isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F6F3);
Color get thCard     => isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
Color get thTxtMain  => isDarkMode ? Colors.white            : const Color(0xFF1A1A1A);
Color get thTxtSub   => isDarkMode ? const Color(0xFF999999) : const Color(0xFF888888);
Color get thInput    => isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
Color get thBorder   => isDarkMode ? const Color(0xFF3A3A3A) : const Color(0xFFE8E8E8);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // Load saved theme
  final savedTheme = prefs.getString('appTheme') ?? 'Light';
  appThemeNotifier.value = savedTheme == 'Dark' ? ThemeMode.dark : ThemeMode.light;

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF8F6F3),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  // ── Light Theme ────────────────────────────────────────────────────────────
  ThemeData get _lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFE87722),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8F6F3),
    canvasColor: const Color(0xFFF8F6F3),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
      titleTextStyle: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w900,
        color: Color(0xFF1A1A1A), letterSpacing: 0.4,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE87722),
        foregroundColor: Colors.white, elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size(double.infinity, 54),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: const Color(0xFFF5F5F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE87722), width: 2)),
      labelStyle: const TextStyle(color: Color(0xFF999999), fontWeight: FontWeight.w400),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFF0F0F0), thickness: 1, space: 1),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );

  // ── Dark Theme ─────────────────────────────────────────────────────────────
  ThemeData get _darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFE87722),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    canvasColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w900,
        color: Colors.white, letterSpacing: 0.4,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E), elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE87722),
        foregroundColor: Colors.white, elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size(double.infinity, 54),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: const Color(0xFF2A2A2A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF3A3A3A), width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF3A3A3A), width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE87722), width: 2)),
      labelStyle: const TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.w400),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFF2A2A2A), thickness: 1, space: 1),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeNotifier,
      builder: (_, mode, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'NAMMA Hotel',
        theme: _lightTheme,
        darkTheme: _darkTheme,
        themeMode: mode,
        home: SplashScreen(isLoggedIn: isLoggedIn),
      ),
    );
  }
}