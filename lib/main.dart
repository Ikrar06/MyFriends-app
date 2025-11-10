import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/contact_provider.dart';
import 'providers/group_provider.dart';
import 'providers/sos_provider.dart';
import 'models/sos_model.dart';

// Global navigator key for navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Push Notifications
  await NotificationService().initialize();

  // Setup notification tap handler
  NotificationService().onNotificationTap = (sosId) {
    if (sosId != null && sosId.isNotEmpty) {
      _handleSOSNotificationTap(sosId);
    }
  };

  runApp(const MyApp());
}

/// Handle SOS notification tap - navigate to SOS detail
Future<void> _handleSOSNotificationTap(String sosId) async {
  try {
    // Wait for navigator to be ready
    await Future.delayed(const Duration(milliseconds: 500));

    // Get SOS message from Firestore
    final doc = await FirebaseFirestore.instance
        .collection('sos_messages')
        .doc(sosId)
        .get();

    if (doc.exists) {
      final sosMessage = SOSMessage.fromFirestore(doc);

      // Navigate to SOS detail screen
      navigatorKey.currentState?.pushNamed(
        AppRoutes.sosDetail,
        arguments: sosMessage,
      );
    }
  } catch (e) {
    debugPrint('Error handling SOS notification tap: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..listenToAuthState(),
        ),

        // Contact Provider - depends on Auth
        ChangeNotifierProxyProvider<AuthProvider, ContactProvider>(
          create: (_) => ContactProvider(),
          update: (_, auth, previous) {
            final provider = previous ?? ContactProvider();
            provider.updateUserId(auth.userId);
            return provider;
          },
        ),

        // Group Provider - depends on Auth
        ChangeNotifierProxyProvider<AuthProvider, GroupProvider>(
          create: (_) => GroupProvider(),
          update: (_, auth, previous) {
            final provider = previous ?? GroupProvider();
            provider.updateUserId(auth.userId);
            return provider;
          },
        ),

        // SOS Provider - depends on Auth
        ChangeNotifierProxyProvider<AuthProvider, SOSProvider>(
          create: (_) => SOSProvider(),
          update: (_, auth, previous) {
            final provider = previous ?? SOSProvider();
            provider.setUserId(auth.userId);
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'MyFriends',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: navigatorKey,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
