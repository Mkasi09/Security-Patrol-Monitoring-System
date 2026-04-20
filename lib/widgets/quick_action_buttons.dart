import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuickActionButtons extends StatelessWidget {
  const QuickActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTheme.heading3.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _QuickActionButton(
                icon: Icons.person_add,
                label: 'Add Guard',
                color: AppTheme.primaryColor,
                onTap: () => _handleAddGuard(context),
              ),
              _QuickActionButton(
                icon: Icons.add_location,
                label: 'Add Location',
                color: AppTheme.infoColor,
                onTap: () => _handleAddLocation(context),
              ),
              _QuickActionButton(
                icon: Icons.manage_accounts,
                label: 'User Management',
                color: AppTheme.warningColor,
                onTap: () => _handleUserManagement(context),
              ),
              _QuickActionButton(
                icon: Icons.assessment,
                label: 'Generate Report',
                color: AppTheme.successColor,
                onTap: () => _handleGenerateReport(context),
              ),

            ],
          ),
        ],
      ),
    );
  }

  void _handleAddGuard(BuildContext context) {
    Navigator.pushNamed(context, '/add_user');
  }

  void _handleAddLocation(BuildContext context) {
    Navigator.pushNamed(context, '/add_location');
  }

  void _handleUserManagement(BuildContext context) {
    Navigator.pushNamed(context, '/user_management');
  }

  void _handleGenerateReport(BuildContext context) {
    _showComingSoonDialog(context, 'Generate Report');
  }

  void _handleQRScanner(BuildContext context) {
    _showComingSoonDialog(context, 'QR Scanner');
  }

  void _handleSendAlert(BuildContext context) {
    _showComingSoonDialog(context, 'Send Alert');
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTheme.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Compact version for smaller spaces
class CompactQuickActions extends StatelessWidget {
  const CompactQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _CompactQuickAction(
            icon: Icons.person_add,
            label: 'Add Guard',
            color: AppTheme.primaryColor,
            onTap: () => Navigator.pushNamed(context, '/add_user'),
          ),
          const SizedBox(width: 12),
          _CompactQuickAction(
            icon: Icons.add_location,
            label: 'Add Location',
            color: AppTheme.infoColor,
            onTap: () => Navigator.pushNamed(context, '/add_location'),
          ),
          const SizedBox(width: 12),
          _CompactQuickAction(
            icon: Icons.manage_accounts,
            label: 'Users',
            color: AppTheme.warningColor,
            onTap: () => Navigator.pushNamed(context, '/user_management'),
          ),
          const SizedBox(width: 12),
          _CompactQuickAction(
            icon: Icons.assessment,
            label: 'Reports',
            color: AppTheme.successColor,
            onTap: () => _showComingSoonDialog(context, 'Generate Report'),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _CompactQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CompactQuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTheme.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
