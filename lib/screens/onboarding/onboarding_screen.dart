import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../routes/app_routes.dart';

/// Onboarding Screen
///
/// Shows 5 slides to introduce the app to first-time users.
/// Tap right side to go next, tap left side to go back.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;

  // Total number of slides
  static const int _totalPages = 5;
  static const int _progressBarPages = 4; // Only show progress for first 4 slides

  /// Mark onboarding as completed
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
  }

  /// Navigate to next page
  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
      });
    } else {
      // Last page, go to register
      _goToRegister();
    }
  }

  /// Navigate to previous page
  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  /// Skip to last slide (register page)
  void _skipToRegister() {
    setState(() {
      _currentPage = _totalPages - 1; // Go to slide 5 (register)
    });
  }

  /// Go to Register screen
  void _goToRegister() async {
    await _completeOnboarding();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.register);
    }
  }

  /// Go to Login screen
  void _goToLogin() async {
    await _completeOnboarding();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView with slides and fade transition
          GestureDetector(
            onTapUp: (details) {
              // Get screen width
              final screenWidth = MediaQuery.of(context).size.width;
              final tapPosition = details.globalPosition.dx;

              // Tap on right half = next, left half = back
              if (tapPosition > screenWidth / 2) {
                _nextPage();
              } else {
                _previousPage();
              }
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: _buildCurrentSlide(),
            ),
          ),

          // Progress indicator at top center (only show for first 4 slides)
          if (_currentPage < _progressBarPages)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: _buildProgressIndicator(),
              ),
            ),

          // Skip button at top right
          if (_currentPage < _totalPages - 1)
            Positioned(
              top: 50,
              right: 20,
              child: TextButton(
                onPressed: _skipToRegister,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build current slide based on page index
  Widget _buildCurrentSlide() {
    Widget slide;
    switch (_currentPage) {
      case 0:
        slide = _buildSlide1();
        break;
      case 1:
        slide = _buildSlide2();
        break;
      case 2:
        slide = _buildSlide3();
        break;
      case 3:
        slide = _buildSlide4();
        break;
      case 4:
        slide = _buildSlide5();
        break;
      default:
        slide = _buildSlide1();
    }
    // Add unique key for AnimatedSwitcher to detect changes
    return KeyedSubtree(
      key: ValueKey<int>(_currentPage),
      child: slide,
    );
  }

  /// Build progress indicator with rounded rectangles (only 4 indicators for first 4 slides)
  Widget _buildProgressIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_progressBarPages, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 24,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  /// Slide 1: Welcome
  Widget _buildSlide1() {
    return Container(
      color: const Color(0xFFFE7743),
      child: Stack(
        children: [
          // Text content at top
          Positioned(
            top: 160,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to\nMyFriends!',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Manage all your friends and contacts in one easy and practical app',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Asset image at bottom right
          Positioned(
            bottom: 0,
            right: 0,
            child: Image.asset(
              'assets/images/onboardingasset1.png',
              fit: BoxFit.contain,
              width: MediaQuery.of(context).size.width * 1,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 800,
                  height: 800,
                  color: Colors.white.withValues(alpha: 0.2),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Slide 2: Organize Contacts
  Widget _buildSlide2() {
    return Container(
      color: const Color(0xFF725CAD),
      child: Stack(
        children: [
          // Asset image at top left
          Positioned(
            top: 0,
            left: 0,
            child: Image.asset(
              'assets/images/onboardingasset2.png',
              fit: BoxFit.contain,
              width: MediaQuery.of(context).size.width * 1,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 800,
                  height: 800,
                  color: Colors.white.withValues(alpha: 0.2),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                );
              },
            ),
          ),

          // Text content at bottom right
          Positioned(
            bottom: 100,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Organize\nContacts Easily',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Arrange contacts into groups like Family, Work Friends, or Close Buddies',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Slide 3: Mark Favorites
  Widget _buildSlide3() {
    return Container(
      color: const Color(0xFF134686),
      child: Stack(
        children: [
          // Text content at top left
          Positioned(
            top: 160,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set Your SOS\nContacts',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Quickly alert trusted people in emergencies by adding them as your SOS contacts.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Asset image at center bottom
          Positioned(
            bottom: -40,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/onboardingasset3.png',
                fit: BoxFit.contain,
                width: MediaQuery.of(context).size.width * 1,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 800,
                    height: 800,
                    color: Colors.white.withValues(alpha: 0.2),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Slide 4: Safe & Stored
  Widget _buildSlide4() {
    return Container(
      color: const Color(0xFF06923E),
      child: Stack(
        children: [
          // Asset image at top right
          Positioned(
            top: 0,
            right: 0,
            child: Image.asset(
              'assets/images/onboardingasset4.png',
              fit: BoxFit.contain,
              width: MediaQuery.of(context).size.width * 1,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 800,
                  height: 800,
                  color: Colors.white.withValues(alpha: 0.2),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                );
              },
            ),
          ),

          // Text content at bottom left
          Positioned(
            bottom: 100,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safe & Stored\nLocally',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'All your contact data is securely stored on your device. No internet needed!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Slide 5: Get Started (with buttons)
  Widget _buildSlide5() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Stack(
        children: [
          // Full size image at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/registerasset.png',
              fit: BoxFit.fitWidth,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 400,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 60,
                    ),
                  ),
                );
              },
            ),
          ),

          // Content at bottom center
          Positioned(
            bottom: 60,
            left: 80,
            right: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                const Text(
                  'Let\'s Get Started',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                const Text(
                  'Join thousands of users organizing contacts better',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 20),

                // Create new account button (Orange)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFE7743),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Create new account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // I already have one button (Gray)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5E7EB),
                      foregroundColor: const Color(0xFF4B5563),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'I already have one',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
