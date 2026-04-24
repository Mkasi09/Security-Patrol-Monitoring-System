import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'notification_badge.dart';

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
            childAspectRatio: 1.0,
            children: [
              AlertCenterButtonWithBadge(
                onTap: () => _handleAlertCenter(context),
                label: 'Alert Center',
                color: AppTheme.infoColor,
              ),
              _QuickActionButton(
                icon: Icons.add_location,
                label: 'Locations',
                color: AppTheme.infoColor,
                onTap: () => _handleLocations(context),
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

  void _handleAlertCenter(BuildContext context) {
    Navigator.pushNamed(context, '/alert_center');
  }

  void _handleLocations(BuildContext context) {
    Navigator.pushNamed(context, '/locations_list');
  }

  void _handleUserManagement(BuildContext context) {
    Navigator.pushNamed(context, '/user_management');
  }

  void _handleGenerateReport(BuildContext context) {
    Navigator.pushNamed(context, '/enhanced_reports');
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
          CompactAlertCenterButtonWithBadge(
            onTap: () => Navigator.pushNamed(context, '/alert_center'),
            label: 'Alert Center',
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          _CompactQuickAction(
            icon: Icons.add_location,
            label: 'Locations',
            color: AppTheme.infoColor,
            onTap: () => Navigator.pushNamed(context, '/locations_list'),
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
            label: 'Alerts',
            color: AppTheme.successColor,
            onTap: () => Navigator.pushNamed(context, '/enhanced_reports'),
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
