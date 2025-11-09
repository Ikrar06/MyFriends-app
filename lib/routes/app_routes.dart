import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/contact/contact_list_screen.dart';
import '../screens/contact/add_contact_screen.dart';
import '../screens/contact/edit_contact_screen.dart';
import '../screens/contact/contact_detail_screen.dart';
import '../screens/contact/favorite_contacts_screen.dart';
import '../screens/group/group_list_screen.dart';
import '../screens/group/add_group_screen.dart';
import '../screens/group/edit_group_screen.dart';
import '../screens/group/group_detail_screen.dart';
import '../models/contact_model.dart';
import '../models/group_model.dart';

/// App Routes
///
/// This file defines all route names and navigation logic.
class AppRoutes {
  // Route Names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';

  // Contact Routes
  static const String contactList = '/contacts';
  static const String addContact = '/contacts/add';
  static const String editContact = '/contacts/edit';
  static const String contactDetail = '/contacts/detail';
  static const String favoriteContacts = '/contacts/favorites';

  // Group Routes
  static const String groupList = '/groups';
  static const String addGroup = '/groups/add';
  static const String editGroup = '/groups/edit';
  static const String groupDetail = '/groups/detail';

  /// Generate Route
  ///
  /// This method handles all route navigation in the app.
  /// Currently returns placeholder screens until screens are created by Orang 1.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );

      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const PlaceholderScreen(title: 'Login Screen'),
          // TODO: Replace with LoginScreen() when created by Orang 1
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => const PlaceholderScreen(title: 'Register Screen'),
          // TODO: Replace with RegisterScreen() when created by Orang 1
        );

      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      case profile:
        return MaterialPageRoute(
          builder: (_) => const PlaceholderScreen(title: 'Profile Screen'),
          // TODO: Replace with ProfileScreen() when created by Orang 1
        );

      case contactList:
        return MaterialPageRoute(
          builder: (_) => const ContactListScreen(),
        );

      case addContact:
        return MaterialPageRoute(
          builder: (_) => const AddContactScreen(),
        );

      case editContact:
        final contact = settings.arguments as Contact?;
        if (contact == null) {
          return MaterialPageRoute(
            builder: (_) => const NotFoundScreen(),
          );
        }
        return MaterialPageRoute(
          builder: (_) => EditContactScreen(contact: contact),
        );

      case contactDetail:
        final contact = settings.arguments as Contact?;
        if (contact == null) {
          return MaterialPageRoute(
            builder: (_) => const NotFoundScreen(),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ContactDetailScreen(contact: contact),
        );

      case favoriteContacts:
        return MaterialPageRoute(
          builder: (_) => const FavoriteContactsScreen(),
        );

      case groupList:
        return MaterialPageRoute(
          builder: (_) => const GroupListScreen(),
        );

      case addGroup:
        return MaterialPageRoute(
          builder: (_) => const AddGroupScreen(),
        );

      case editGroup:
        final group = settings.arguments as Group?;
        if (group == null) {
          return MaterialPageRoute(
            builder: (_) => const NotFoundScreen(),
          );
        }
        return MaterialPageRoute(
          builder: (_) => EditGroupScreen(group: group),
        );

      case groupDetail:
        final group = settings.arguments as Group?;
        if (group == null) {
          return MaterialPageRoute(
            builder: (_) => const NotFoundScreen(),
          );
        }
        return MaterialPageRoute(
          builder: (_) => GroupDetailScreen(group: group),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const NotFoundScreen(),
        );
    }
  }
}

/// Placeholder Screen
///
/// Temporary screen used until actual screens are implemented.
/// Will be removed once all screens are created.
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: 100,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This screen will be implemented soon',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 404 Not Found Screen
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('404'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 100,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              '404',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              },
              icon: const Icon(Icons.home),
              label: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
