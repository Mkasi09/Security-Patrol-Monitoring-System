import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:magzmotron/firebase_options.dart';
import 'package:magzmotron/screens/admin_add_location_screen.dart';
import 'package:magzmotron/screens/admin_report_screen.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/guard_home_screen.dart';
import 'screens/manager_dashboard_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/add_user_screen.dart';
import 'screens/password_reset_screen.dart';
import 'screens/patrol_history_screen.dart';
import 'theme/app_theme.dart';

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
        theme: AppTheme.lightTheme,
        initialRoute: '/login',
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
          '/user_management': (context) => const UserManagementScreen(),
          '/add_user': (context) => const AddUserScreen(),
          '/add_location': (context) => const AdminAddLocationScreen(),
          '/password_reset': (context) => const PasswordResetScreen(),
          '/patrol_history': (context) => const PatrolHistoryScreen(),
          '/all_reports': (context) => const AdminReportScreen(),
        },
      ),
    );
  }
}
