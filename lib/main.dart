import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myfriends_app/providers/auth_provider.dart';
import 'package:myfriends_app/services/firebase_service.dart'; // Menggantikan firebase_core

import 'services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';

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