import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/validators.dart';
import '../../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.resetPassword(_emailController.text.trim());

      if (!mounted) return;

      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset email has been sent! Check your inbox.',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      // Kembali ke login screen
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      // Tampilkan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString()}',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3142)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Icon
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFE7743).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      size: 60,
                      color: Color(0xFFFE7743),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'Forgot Password?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  const Text(
                    'Enter your email address and we will send you a link to reset your password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(fontFamily: 'Poppins'),
                      hintText: 'Enter your email',
                      hintStyle: const TextStyle(fontFamily: 'Poppins'),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Color(0xFFFE7743),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFFE7743),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontFamily: 'Poppins'),
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 32),

                  // Send Reset Email Button
                  CustomButton(
                    text: 'Send Reset Email',
                    onPressed: _isLoading ? null : _handleResetPassword,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Back to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Remember your password? ',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.grey,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFFFE7743),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
