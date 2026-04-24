import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ModernNavigationDrawer extends StatelessWidget {
  final String currentPage;
  final String userRole;

  const ModernNavigationDrawer({
    super.key,
    required this.currentPage,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(top: 20, bottom: 20, left: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            _buildHeader(user),
            const SizedBox(height: 10),

            /// MENU
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (userRole == 'manager') ...[
                    _item(context, Icons.dashboard, "Dashboard", currentPage == 'dashboard'),
                    _item(context, Icons.assessment, "Reports", currentPage == 'reports'),
                    _item(context, Icons.people, "Guards", currentPage == 'guards'),
                    _item(context, Icons.location_on, "Locations", currentPage == 'locations'),
                    _item(context, Icons.manage_accounts, "User Management", currentPage == 'user_management'),
                  ] else ...[
                    _item(context, Icons.home, "Home", currentPage == 'home'),
                    _item(context, Icons.qr_code_scanner, "Scan Location", currentPage == 'scan'),
                    _item(context, Icons.history, "My Reports", currentPage == 'history'),
                  ],

                  const SizedBox(height: 10),
                  const Divider(),

                  _item(context, Icons.settings, "Settings", false),
                  _item(context, Icons.help_outline, "Help & Support", false),
                ],
              ),
            ),

            /// LOGOUT
            _logout(context),
          ],
        ),
      ),
    );
  }

  /// 🔹 HEADER (Cleaner + safer)
  Widget _buildHeader(user) {
    String name = user?.name ?? "User";
    String email = user?.email ?? "";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : "U",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    userRole == 'manager' ? "Manager" : "Guard",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  /// 🔹 MENU ITEM (Modern Style)
  Widget _item(BuildContext context, IconData icon, String title, bool selected) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        // Handle navigation for specific items
        if (title == "User Management") {
          Navigator.pushNamed(context, '/user_management');
        } else if (title == "My Reports") {
          Navigator.pushNamed(context, '/patrol_history');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? AppTheme.primaryColor
                      : AppTheme.textPrimary,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.circle, size: 8, color: AppTheme.primaryColor)
          ],
        ),
      ),
    );
  }

  /// 🔹 LOGOUT
  Widget _logout(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () async {
            await auth.signOut();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.logout, color: AppTheme.errorColor),
                const SizedBox(width: 10),
                const Text("Logout",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}