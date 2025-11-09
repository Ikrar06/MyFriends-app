import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:myfriends_app/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Splash Screen
///
/// Displays app logo and characters with animations.
/// Checks if first time user and authentication status,
/// then routes to appropriate screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _charactersController;

  // Animations
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _charactersFadeAnimation;
  late Animation<double> _charactersScaleAnimation;
  late Animation<Offset> _charactersSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _checkInitialRoute();
  }

  /// Initialize all animations
  void _initAnimations() {
    // Logo animation controller (0.8 seconds)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Characters animation controller (1 second, delayed)
    _charactersController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Logo fade in animation
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeIn,
      ),
    );

    // Logo scale animation
    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );

    // Characters fade in animation
    _charactersFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _charactersController,
        curve: Curves.easeIn,
      ),
    );

    // Characters scale animation
    _charactersScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _charactersController,
        curve: Curves.easeOutBack,
      ),
    );

    // Characters slide up animation
    _charactersSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _charactersController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  /// Start animations sequentially
  void _startAnimations() async {
    // Start logo animation immediately
    await _logoController.forward();

    // Start characters animation after logo completes
    await Future.delayed(const Duration(milliseconds: 200));
    await _charactersController.forward();
  }

  /// Check initial route based on auth and first time status
  Future<void> _checkInitialRoute() async {
    // Tunggu animasi selesai
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    try {
      // 1. Cek status Auth (Tugas Orang 1)
      final authProvider = context.read<AuthProvider>();

      // 2. Cek status Onboarding (Tugas Orang 2)
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('isFirstTime') ?? true;

      // --- LOGIKA UTAMA ---
      if (authProvider.isAuthenticated) {
        // KASUS 1: Pengguna sudah login.
        // Langsung arahkan ke Home, tidak peduli status onboarding.
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        
      } else {
        // KASUS 2: Pengguna BELUM login.
        if (isFirstTime) {
          // Jika ini pertama kali buka aplikasi, arahkan ke Onboarding.
          Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
        } else {
          // Jika sudah pernah lihat onboarding, langsung ke Login.
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      }
    } catch (e) {
      // Jika ada error, arahkan ke login sebagai failsafe.
      if (kDebugMode) {
        print('Error di _checkInitialRoute: $e');
      }
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _charactersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // Logo at top center (with SafeArea)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: ScaleTransition(
                    scale: _logoScaleAnimation,
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo_splash.png',
                        width: 280,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Characters at absolute bottom (NO SafeArea)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _charactersFadeAnimation,
              child: SlideTransition(
                position: _charactersSlideAnimation,
                child: ScaleTransition(
                  scale: _charactersScaleAnimation,
                  child: Image.asset(
                    'assets/images/splash.png',
                    fit: BoxFit.fitWidth,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}