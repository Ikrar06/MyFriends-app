import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:myfriends_app/providers/auth_provider.dart';
import 'package:myfriends_app/services/firebase_service.dart'; // Menggantikan firebase_core

import 'services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/contact_provider.dart';
import 'providers/group_provider.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 3. GANTI INISIALISASI FIREBASE MANUAL
  //    dengan FirebaseService yang terpusat
  await FirebaseService.initialize();

  // Initialize Push Notifications
  await NotificationService().initialize();

  // 4. BUNGKUS runApp DENGAN MultiProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        // Nanti kita akan tambahkan ContactProvider & GroupProvider di sini
      ],
      child: const MyApp(),
    ),
  );
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
      ],
      child: MaterialApp(
        title: 'MyFriends',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // TEMPORARY: Direct to home screen for UI testing (bypass auth)
        home: const HomeScreen(),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    // 5. TIDAK ADA PERUBAHAN DI SINI
    //    Struktur ini sudah sempurna.
    return MaterialApp(
      title: 'MyFriends',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}