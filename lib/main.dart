import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/onboarding_page.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/account_page.dart';
import 'pages/history_page.dart';
import 'services/auth_service.dart';

import 'pages/warehouse_selection_page.dart';
import 'services/warehouse_service.dart';
import 'services/background_location_service.dart';
import 'pages/store_dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundLocationService.initializeService();

  // Keep the navigation bar opaque but match the background color so it
  // blends in — this avoids content being hidden behind the nav bar
  // while still looking clean without the harsh black bar.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xFFF8F9FB),
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FAM ZLOG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1580C1)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Color(0xFFF8F9FB),
          ),
        ),
      ),
      // Wrap all pages with SafeArea bottom to prevent content from
      // being hidden behind the Android gesture / button navigation bar.
      builder: (context, child) {
        return SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: true,
          child: child!,
        );
      },
      routes: {
        '/': (_) => const _RootPage(),
        '/onboarding': (_) => const OnboardingPage(),
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/forgot-password': (_) => const ForgotPasswordPage(),
        '/account': (_) => const AccountPage(),
        '/history': (_) => const HistoryPage(),
        '/warehouse-selection': (_) => const WarehouseSelectionPage(),
      },
      initialRoute: '/',
    );
  }
}

class _RootPage extends StatefulWidget {
  const _RootPage();

  @override
  State<_RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<_RootPage> {
  @override
  void initState() {
    super.initState();
    _decideStart();
  }

  Future<void> _decideStart() async {
    final ok = await AuthService.tryAutoLogin();
    if (!mounted) return;
    if (ok) {
      final user = AuthService.currentUser;
      if (user?.role == 'store') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StoreDashboardPage()),
        );
        return;
      }

      final warehouseId = await WarehouseService.getSelectedWarehouseId();
      if (!mounted) return;
      if (warehouseId != null) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/warehouse-selection');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
