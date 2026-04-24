import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../services/alert_service.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_drawer.dart';

class AlertCenterScreen extends StatefulWidget {
  const AlertCenterScreen({super.key});

  @override
  State<AlertCenterScreen> createState() => _AlertCenterScreenState();
}

class _AlertCenterScreenState extends State<AlertCenterScreen> {
  final AlertService _alertService = AlertService();
  bool _isLoading = false;
  List<Alert> _newAlerts = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNewAlerts();
  }

  Future<void> _loadNewAlerts() async {
    setState(() => _isLoading = true);
    try {
      // Get only active alerts from guards (status: active)
      final alerts = await _alertService.getAlerts(
        status: AlertStatus.active,
        limit: 100,
      );
      
      // Filter to show only alerts reported by guards (not system alerts)
      final guardAlerts = alerts.where((alert) => 
        alert.guardId != null && alert.guardId!.isNotEmpty
      ).toList();

      setState(() {
        _newAlerts = guardAlerts;
        _unreadCount = guardAlerts.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load alerts: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _markAsRead(String alertId) async {
    try {
      await _alertService.updateAlertStatus(alertId, AlertStatus.acknowledged);
      _showSuccessSnackBar('Alert marked as read');
      _loadNewAlerts(); // Refresh the list
    } catch (e) {
      _showErrorSnackBar('Failed to mark as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(
        title: 'New Guard Alerts',
        actions: [
          // Show red badge with count
          if (_unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNewAlerts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _newAlerts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _newAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = _newAlerts[index];
                      return _buildAlertCard(alert);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No new alerts',
            style: AppTheme.heading3.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'All reports from security guards have been reviewed',
            style: AppTheme.body2.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Alert alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showAlertDetails(alert),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with priority indicator
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(alert.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      alert.priority.name.toUpperCase(),
                      style: TextStyle(
                        color: _getPriorityColor(alert.priority),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimeAgo(alert.createdAt),
                    style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
                  ),
                  const Spacer(),
                  // Red dot for unopened
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Alert Title
              Text(
                alert.title,
                style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              // Guard Name
              if (alert.guardName != null)
                Text(
                  'From: ${alert.guardName}',
                  style: AppTheme.body2.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 8),
              // Message preview
              Text(
                alert.message,
                style: AppTheme.body2,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Mark as read button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _markAsRead(alert.id),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Mark as Read'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.successColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlertDetails(Alert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getPriorityColor(alert.priority),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(alert.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (alert.guardName != null)
                _buildDetailRow('Guard:', alert.guardName!),
              if (alert.locationName != null)
                _buildDetailRow('Location:', alert.locationName!),
              _buildDetailRow('Priority:', alert.priority.name),
              _buildDetailRow('Time:', _formatTimeAgo(alert.createdAt)),
              const SizedBox(height: 12),
              const Text(
                'Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(alert.message),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _markAsRead(alert.id);
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Mark as Read'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getPriorityColor(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.critical:
        return Colors.red;
      case AlertPriority.high:
        return Colors.orange;
      case AlertPriority.medium:
        return Colors.blue;
      case AlertPriority.low:
        return Colors.green;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
