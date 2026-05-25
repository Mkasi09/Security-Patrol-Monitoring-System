import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../models/report.dart';
import '../services/alert_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_drawer.dart';
import 'report_detail_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AlertService _alertService = AlertService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AdminAppBar(
        title: 'Operations',
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note),
            onPressed: () => Navigator.pushNamed(context, '/patrol_schedule'),
            tooltip: 'Patrol schedule',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () => Navigator.pushNamed(context, '/alert_center'),
            tooltip: 'Alert center',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _buildCommandHeader(),
            const SizedBox(height: 16),
            FutureBuilder<_DashboardData>(
              future: _loadDashboardData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Text('Failed to load dashboard: ${snapshot.error}');
                }

                final data = snapshot.data ?? _DashboardData.empty();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricsGrid(data),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Priority Alerts', 'View All', () {
                      Navigator.pushNamed(context, '/alert_center');
                    }),
                    const SizedBox(height: 10),
                    _buildPriorityAlerts(data.alerts),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Recent Reports', 'View All', () {
                      Navigator.pushNamed(context, '/all_reports');
                    }),
                    const SizedBox(height: 10),
                    _buildRecentReports(data.reports),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<_DashboardData> _loadDashboardData() async {
    final reports = await _firestoreService.getAllReports();
    final alerts = await _alertService.getAlerts(limit: 50);
    return _DashboardData(reports: reports, alerts: alerts);
  }

  Widget _buildCommandHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.security, color: Colors.white, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Security Command Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Monitor patrols, incidents, schedules, and response work.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(_DashboardData data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _metricCard(
          'Today Reports',
          data.todayReports,
          Icons.fact_check,
          AppTheme.primaryColor,
        ),
        _metricCard(
          'Emergencies',
          data.emergencyReports,
          Icons.emergency,
          AppTheme.errorColor,
        ),
        _metricCard(
          'Open Alerts',
          data.openAlerts,
          Icons.notifications_active,
          AppTheme.warningColor,
        ),
        _metricCard(
          'Resolved',
          data.resolvedAlerts,
          Icons.verified,
          AppTheme.successColor,
        ),
      ],
    );
  }

  Widget _metricCard(String title, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  title,
                  style: AppTheme.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _DashboardAction(
        Icons.event_note,
        'Schedule',
        '/patrol_schedule',
        AppTheme.primaryColor,
      ),
      _DashboardAction(
        Icons.notifications_active,
        'Alerts',
        '/alert_center',
        AppTheme.errorColor,
      ),
      _DashboardAction(
        Icons.location_on,
        'Locations',
        '/locations_list',
        AppTheme.warningColor,
      ),
      _DashboardAction(
        Icons.people,
        'Users',
        '/user_management',
        AppTheme.secondaryColor,
      ),
    ];

    return Row(
      children: actions.map((action) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, action.route),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(action.icon, color: action.color),
                    const SizedBox(height: 6),
                    Text(
                      action.label,
                      style: AppTheme.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title, String action, VoidCallback onTap) {
    return Row(
      children: [
        Text(title, style: AppTheme.heading3),
        const Spacer(),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    );
  }

  Widget _buildPriorityAlerts(List<Alert> alerts) {
    final priorityAlerts = alerts
        .where((alert) => alert.status != AlertStatus.resolved)
        .take(4)
        .toList();

    if (priorityAlerts.isEmpty) {
      return _emptyPanel(
        'No open alerts',
        'New emergency and suspicious activity alerts will show here.',
      );
    }

    return Column(
      children: priorityAlerts.map((alert) {
        final color = _priorityColor(alert.priority);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.warning, color: color),
            ),
            title: Text(
              alert.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              alert.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/alert_center'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentReports(List<Report> reports) {
    final recentReports = reports.take(5).toList();
    if (recentReports.isEmpty) {
      return _emptyPanel(
        'No reports yet',
        'Submitted guard reports will appear here.',
      );
    }

    return Column(
      children: recentReports.map((report) {
        final color = _reportColor(report.status);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(_reportIcon(report.status), color: color),
            ),
            title: Text(
              report.locationName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${report.userName} - ${_formatTime(report.timestamp)}',
            ),
            trailing: report.imageUrl != null
                ? const Icon(Icons.image, color: AppTheme.secondaryColor)
                : const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportDetailScreen(report: report),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyPanel(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(title, style: AppTheme.subtitle1),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTheme.body2, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Color _priorityColor(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.critical:
        return AppTheme.errorColor;
      case AlertPriority.high:
        return AppTheme.warningColor;
      case AlertPriority.medium:
        return AppTheme.infoColor;
      case AlertPriority.low:
        return AppTheme.successColor;
    }
  }

  Color _reportColor(String status) {
    switch (status) {
      case 'emergency':
        return AppTheme.errorColor;
      case 'suspicious':
        return AppTheme.warningColor;
      default:
        return AppTheme.successColor;
    }
  }

  IconData _reportIcon(String status) {
    switch (status) {
      case 'emergency':
        return Icons.emergency;
      case 'suspicious':
        return Icons.warning;
      default:
        return Icons.check_circle;
    }
  }

  String _formatTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _DashboardData {
  final List<Report> reports;
  final List<Alert> alerts;

  _DashboardData({required this.reports, required this.alerts});

  factory _DashboardData.empty() => _DashboardData(reports: [], alerts: []);

  int get todayReports {
    final now = DateTime.now();
    return reports.where((report) {
      return report.timestamp.year == now.year &&
          report.timestamp.month == now.month &&
          report.timestamp.day == now.day;
    }).length;
  }

  int get emergencyReports =>
      reports.where((report) => report.status == 'emergency').length;

  int get openAlerts =>
      alerts.where((alert) => alert.status != AlertStatus.resolved).length;

  int get resolvedAlerts =>
      alerts.where((alert) => alert.status == AlertStatus.resolved).length;
}

class _DashboardAction {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  _DashboardAction(this.icon, this.label, this.route, this.color);
}
