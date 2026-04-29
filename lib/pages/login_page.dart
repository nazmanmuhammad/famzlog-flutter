import 'package:flutter/material.dart';
import 'package:famzlog_flutter/services/auth_service.dart';
import 'package:famzlog_flutter/services/warehouse_service.dart';
import 'package:famzlog_flutter/pages/store_dashboard_page.dart';
import 'package:famzlog_flutter/widgets/modern_snackbar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1580C1);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    // Branding: dot + FAM ZLOG
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'FAM ZLOG',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // Welcome heading
                    const Text(
                      'Welcome Back\nto FAM ZLOG',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hello there, sign in to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Email Address label
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'Email Address',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'hikiitbaee@gmail.com',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFE3F2FD).withOpacity(0.3),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: primary.withOpacity(0.3),
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: primary,
                            width: 1.6,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.2,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.6,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email wajib diisi';
                        }
                        if (!value.contains('@')) {
                          return 'Email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Password label + Forgot?
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 4,
                        bottom: 8,
                        right: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(
                                context,
                              ).pushNamed('/forgot-password');
                            },
                            child: const Text(
                              'Forgot?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFE3F2FD).withOpacity(0.3),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          color: Colors.grey.shade500,
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: primary.withOpacity(0.3),
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: primary,
                            width: 1.6,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.2,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.6,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password wajib diisi';
                        }
                        if (value.length < 6) {
                          return 'Minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    // Login button
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _loading
                            ? null
                            : () async {
                                if (!(_formKey.currentState?.validate() ??
                                    false)) {
                                  return;
                                }
                                setState(() {
                                  _loading = true;
                                });
                                try {
                                  final auth = await AuthService.login(
                                    _emailController.text.trim(),
                                    _passwordController.text,
                                  );
                                  await AuthService.fetchMe();
                                  
                                  // Role validation
                                  final role = auth.user.role.toLowerCase();
                                  // if (role != 'driver' && role != 'shipment' && role != 'store') {
                                  //   await AuthService.logout();
                                  //   if (!mounted) return;
                                  //   showModernSnackBar(
                                  //     context,
                                  //     title: 'Akses Ditolak',
                                  //     message: 'Kamu hanya bisa login di web saja',
                                  //     success: false,
                                  //   );
                                  //   return;
                                  // }

                                  if (!mounted) return;
                                  showModernSnackBar(
                                    context,
                                    title: 'Login Berhasil',
                                    message:
                                        'Selamat datang, ${auth.user.name}',
                                    success: true,
                                  );

                                  if (auth.user.role == 'store') {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const StoreDashboardPage(),
                                      ),
                                    );
                                    return;
                                  }

                                  final warehouseId =
                                      await WarehouseService.getSelectedWarehouseId();
                                  if (!mounted) return;

                                  if (warehouseId != null) {
                                    Navigator.of(
                                      context,
                                    ).pushReplacementNamed('/home');
                                  } else {
                                    Navigator.of(context).pushReplacementNamed(
                                      '/warehouse-selection',
                                    );
                                  }
                                } on AuthException catch (e) {
                                  if (!mounted) return;
                                  showModernSnackBar(
                                    context,
                                    title: 'Login Gagal',
                                    message: e.message,
                                    success: false,
                                  );
                                } catch (_) {
                                  if (!mounted) return;
                                  showModernSnackBar(
                                    context,
                                    title: 'Error',
                                    message:
                                        'Terjadi kesalahan pada server, coba lagi.',
                                    success: false,
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _loading = false;
                                    });
                                  }
                                }
                              },
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Or continue with social account
                    // Text(
                    //   'Or continue with social account',
                    //   textAlign: TextAlign.center,
                    //   style: TextStyle(
                    //     fontSize: 13,
                    //     color: Colors.grey.shade500,
                    //   ),
                    // ),
                    // const SizedBox(height: 20),
                    // Google button
                    // _SocialButton(
                    //   icon: Icons.g_mobiledata_rounded,
                    //   label: 'Sign in with Google',
                    //   iconColor: Colors.red.shade600,
                    // ),
                    // const SizedBox(height: 12),
                    // // Facebook button
                    // _SocialButton(
                    //   icon: Icons.facebook_rounded,
                    //   label: 'Sign in with Facebook',
                    //   iconColor: Colors.blue.shade700,
                    // ),
                    // const SizedBox(height: 28),
                    // Don't have an account? Signup
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     Text(
                    //       "Don't have an account? ",
                    //       style: TextStyle(
                    //         fontSize: 13,
                    //         color: Colors.grey.shade600,
                    //       ),
                    //     ),
                    //     GestureDetector(
                    //       onTap: () {},
                    //       child: const Text(
                    //         'Signup',
                    //         style: TextStyle(
                    //           fontSize: 13,
                    //           fontWeight: FontWeight.w700,
                    //           color: primary,
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        icon: Icon(icon, color: iconColor, size: 24),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
