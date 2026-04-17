import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:magzmotron/firebase_options.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/guard_home_screen.dart';
import 'screens/manager_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Security Patrol Monitoring System',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: '/home',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) {
            final authProvider = Provider.of<AuthProvider>(context);
            // For demo purposes, default to guard view
            // In real app, determine role from Firestore
            return authProvider.currentUser?.role == 'manager'
                ? const ManagerDashboardScreen()
                : const GuardHomeScreen();
          },
          '/guard': (context) => const GuardHomeScreen(),
          '/manager': (context) => const ManagerDashboardScreen(),
        },
      ),
    );
  }
}
