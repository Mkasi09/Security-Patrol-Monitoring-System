import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:magzmotron/firebase_options.dart';
import 'package:magzmotron/screens/locations_list_screen.dart';
import 'package:magzmotron/screens/active_guards_screen.dart';
import 'package:magzmotron/screens/enhanced_report_screen.dart';
import 'package:magzmotron/screens/alert_center_screen.dart';
import 'package:magzmotron/screens/admin_add_location_screen.dart';
import 'package:magzmotron/screens/bulk_qr_generator_screen.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'widgets/auth_wrapper.dart';
import 'screens/forgot_password_screen.dart';
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
        home: const AuthWrapper(),
        routes: {
          '/forgot_password': (context) => const ForgotPasswordScreen(),
          '/guard': (context) => const GuardHomeScreen(),
          '/manager': (context) => const ManagerDashboardScreen(),
          '/user_management': (context) => const UserManagementScreen(),
          '/add_user': (context) => const AddUserScreen(),
          '/active_guards': (context) => const ActiveGuardsScreen(),
          '/locations_list': (context) => const LocationsListScreen(),
          '/add_location': (context) => const AdminAddLocationScreen(),
          '/password_reset': (context) => const PasswordResetScreen(),
          '/patrol_history': (context) => const PatrolHistoryScreen(),
          '/alert_center': (context) => const AdminAlertScreen(),
          '/enhanced_reports': (context) => const EnhancedReportScreen(),
          '/all_reports': (context) => const AdminAlertScreen(),
          '/bulk_qr_generator': (context) => const BulkQRGeneratorScreen(),
        },
      ),
    );
  }
}
