import 'package:flutter/material.dart';
import 'package:myfriends_app/core/utils/validators.dart';
import 'package:myfriends_app/providers/auth_provider.dart';
import 'package:myfriends_app/routes/app_routes.dart';
import 'package:myfriends_app/widgets/custom_button.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. State properties sesuai panduan
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // 2. Helper untuk menampilkan Snackbar
  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return; // Cek jika widget masih ada
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Colors.green,
      ),
    );
  }

  // 3. Logika _handleLogin sesuai panduan
  Future<void> _handleLogin() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) return;

    // Panggil AuthProvider
    final authProvider = context.read<AuthProvider>();

    try {
      // Panggil signIn dari provider
      await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Jika berhasil, provider akan update state
      // dan SplashScreen akan otomatis redirect
      if (mounted) {
        _showSnackbar('Login successful');
        // Navigasi ke home
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      // Tangkap error dari provider dan tampilkan
      if (mounted) {
        _showSnackbar(e.toString(), isError: true);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 60),

                      // Logo & Icon
                      Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFE7743).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.people_alt,
                          size: 60,
                          color: Color(0xFFFE7743),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Welcome Text
                      const Text(
                        'Welcome Back!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(fontFamily: 'Poppins'),
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFE7743)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFE7743), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontFamily: 'Poppins'),
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(fontFamily: 'Poppins'),
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFE7743)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFE7743), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontFamily: 'Poppins'),
                        validator: Validators.validatePassword,
                      ),
                      const SizedBox(height: 12),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.forgotPassword);
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xFFFE7743),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Button
                      CustomButton(
                        text: 'Sign In',
                        onPressed: authProvider.isLoading ? null : _handleLogin,
                        isLoading: authProvider.isLoading,
                      ),
                      const SizedBox(height: 24),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Don\'t have an account? ',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.grey,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.register);
                            },
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Color(0xFFFE7743),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}