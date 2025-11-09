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
        _showSnackbar('Login berhasil');
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
    // Gunakan Consumer untuk listen ke state 'isLoading' dari AuthProvider
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          // Gunakan AppBar agar konsisten
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // UI Sesuai Panduan
                  const SizedBox(height: 40),
                  Icon(
                    Icons.people_alt,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Login to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),

                  // Form Field Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail, // Dari file Anda
                  ),
                  const SizedBox(height: 16),

                  // Form Field Password
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: Validators.validatePassword, // Dari file Anda
                  ),
                  const SizedBox(height: 32),

                  // Tombol Login
                  // Menggunakan CustomButton dari Orang 2
                  CustomButton(
                    text: 'Login',
                    onPressed: authProvider.isLoading ? null : _handleLogin,
                    isLoading: authProvider.isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Link ke Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.register);
                        },
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}