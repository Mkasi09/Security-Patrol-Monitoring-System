import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/alert_service.dart';
import '../services/notification_refresh_service.dart';
import '../models/alert.dart';

class NotificationBadge extends StatefulWidget {
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;
  final bool showBadge;
  final int? count;

  const NotificationBadge({
    super.key,
    required this.child,
    this.badgeColor,
    this.textColor,
    this.showBadge = true,
    this.count,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final AlertService _alertService = AlertService();
  final NotificationRefreshService _refreshService = NotificationRefreshService();
  int _newAlertsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNewAlertsCount();
    // Listen for refresh notifications
    _refreshService.addListener(refreshBadge);
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    _refreshService.removeListener(refreshBadge);
    super.dispose();
  }

  // Public method to refresh the badge count
  void refreshBadge() {
    _loadNewAlertsCount();
  }

  Future<void> _loadNewAlertsCount() async {
    try {
      // Get only active alerts from guards
      final alerts = await _alertService.getAlerts(
        status: AlertStatus.active,
        limit: 100,
      );
      
      // Filter to show only alerts reported by guards
      final guardAlerts = alerts.where((alert) => 
        alert.guardId != null && alert.guardId!.isNotEmpty
      ).toList();

      if (mounted) {
        setState(() {
          _newAlertsCount = guardAlerts.length;
        });
      }
    } catch (e) {
      debugPrint('Failed to load alerts count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayCount = widget.count ?? _newAlertsCount;
    final shouldShowBadge = widget.showBadge && displayCount > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (shouldShowBadge)
              Positioned(
                right: -4,
                top: -4,
                child: _buildBadge(displayCount),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBadge(int count) {
    final badgeColor = widget.badgeColor ?? AppTheme.errorColor;
    final textColor = widget.textColor ?? Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class AlertCenterButtonWithBadge extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final Color color;

  const AlertCenterButtonWithBadge({
    super.key,
    required this.onTap,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: NotificationBadge(
        badgeColor: AppTheme.errorColor,
        child: _QuickActionButton(
          icon: Icons.notifications_active,
          label: label,
          color: color,
          onTap: onTap,
        ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: SizedBox.expand(
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
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 300),
                        tween: Tween(begin: 0.8, end: 1.0),
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Icon(
                              icon,
                              size: 28,
                              color: color,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTheme.body2.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CompactAlertCenterButtonWithBadge extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final Color color;

  const CompactAlertCenterButtonWithBadge({
    super.key,
    required this.onTap,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationBadge(
      badgeColor: AppTheme.errorColor,
      child: _CompactQuickAction(
        icon: Icons.notifications_active,
        label: label,
        color: color,
        onTap: onTap,
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
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.body2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
