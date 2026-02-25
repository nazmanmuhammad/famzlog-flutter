import 'package:flutter/material.dart';
import 'pages/onboarding_page.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/account_page.dart';
import 'pages/history_page.dart';
import 'services/auth_service.dart';

import 'pages/warehouse_selection_page.dart';
import 'services/warehouse_service.dart';

void main() {
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
      ),
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
