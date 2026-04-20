import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool showProfile;
  final VoidCallback? onProfileTap;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;

  const ModernAppBar({ 
    
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.showProfile = false,
    this.onProfileTap,
    this.flexibleSpace,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: backgroundColor != null 
            ? [backgroundColor!, backgroundColor!]
            : [AppTheme.primaryColor, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        title: _buildTitle(context),
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        centerTitle: centerTitle,
        backgroundColor: Colors.transparent,
        elevation: elevation ?? 0,
        flexibleSpace: flexibleSpace,
        bottom: bottom,
        iconTheme: IconThemeData(
          color: foregroundColor ?? Colors.white,
          size: 24,
        ),
        titleTextStyle: AppTheme.heading3.copyWith(
          color: foregroundColor ?? Colors.white,
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (centerTitle) ...[
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Text(
          title,
          style: AppTheme.heading3.copyWith(
            color: foregroundColor ?? Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (centerTitle) ...[
          const SizedBox(width: 12),
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ],
    );
  }



  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'manager':
        return AppTheme.secondaryColor;
      case 'guard':
        return AppTheme.primaryColor;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplay(String? role) {
    switch (role) {
      case 'manager':
        return 'Manager';
      case 'guard':
        return 'Security Guard';
      default:
        return 'User';
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
