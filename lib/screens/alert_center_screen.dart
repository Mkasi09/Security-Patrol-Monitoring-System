import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alert.dart';
import '../providers/auth_provider.dart';
import '../services/alert_service.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_drawer.dart';

class AdminAlertScreen extends StatefulWidget {
  const AdminAlertScreen({super.key});

  @override
  State<AdminAlertScreen> createState() => _AdminAlertScreenState();
}

class _AdminAlertScreenState extends State<AdminAlertScreen> {
  final AlertService _alertService = AlertService();

  AlertStatus? _statusFilter;
  AlertPriority? _priorityFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AdminAppBar(
        title: 'Alert Center',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<Alert>>(
        future: _alertService.getAlerts(limit: 200),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(message: snapshot.error.toString());
          }

          final alerts = _filterAlerts(snapshot.data ?? []);
          return Column(
            children: [
              _buildSummary(snapshot.data ?? []),
              _buildFilters(),
              Expanded(
                child: alerts.isEmpty
                    ? const _EmptyState()
                    : RefreshIndicator(
                        onRefresh: () async => setState(() {}),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: alerts.length,
                          itemBuilder: (context, index) {
                            return _buildAlertCard(alerts[index]);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Alert> _filterAlerts(List<Alert> alerts) {
    return alerts.where((alert) {
      if (_statusFilter != null && alert.status != _statusFilter) return false;
      if (_priorityFilter != null && alert.priority != _priorityFilter) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;

      final query = _searchQuery.toLowerCase();
      return alert.title.toLowerCase().contains(query) ||
          alert.message.toLowerCase().contains(query) ||
          (alert.locationName ?? '').toLowerCase().contains(query) ||
          (alert.guardName ?? '').toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildSummary(List<Alert> alerts) {
    final active = alerts.where((a) => a.status == AlertStatus.active).length;
    final critical = alerts
        .where(
          (a) =>
              a.priority == AlertPriority.critical &&
              a.status != AlertStatus.resolved,
        )
        .length;
    final acknowledged = alerts
        .where((a) => a.status == AlertStatus.acknowledged)
        .length;
    final resolved = alerts
        .where((a) => a.status == AlertStatus.resolved)
        .length;

    return Container(
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(child: _summaryTile('Active', active, AppTheme.errorColor)),
          const SizedBox(width: 8),
          Expanded(
            child: _summaryTile('Critical', critical, Colors.deepPurple),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _summaryTile('Ack', acknowledged, AppTheme.warningColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _summaryTile('Resolved', resolved, AppTheme.successColor),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.caption, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search alerts, guards, or locations',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(
                  'All',
                  _statusFilter == null && _priorityFilter == null,
                  () {
                    setState(() {
                      _statusFilter = null;
                      _priorityFilter = null;
                    });
                  },
                ),
                _filterChip('Active', _statusFilter == AlertStatus.active, () {
                  setState(() => _statusFilter = AlertStatus.active);
                }),
                _filterChip(
                  'Acknowledged',
                  _statusFilter == AlertStatus.acknowledged,
                  () {
                    setState(() => _statusFilter = AlertStatus.acknowledged);
                  },
                ),
                _filterChip(
                  'Resolved',
                  _statusFilter == AlertStatus.resolved,
                  () {
                    setState(() => _statusFilter = AlertStatus.resolved);
                  },
                ),
                _filterChip(
                  'Critical',
                  _priorityFilter == AlertPriority.critical,
                  () {
                    setState(() => _priorityFilter = AlertPriority.critical);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _buildAlertCard(Alert alert) {
    final priorityColor = _priorityColor(alert.priority);
    final statusColor = _statusColor(alert.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAlertDetails(alert),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _priorityIcon(alert.priority),
                      color: priorityColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert.title, style: AppTheme.subtitle1),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(alert.createdAt),
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  ),
                  _statusPill(alert.status, statusColor),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alert.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.body2.copyWith(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (alert.guardName != null)
                    _metaChip(Icons.person, alert.guardName!),
                  if (alert.locationName != null)
                    _metaChip(Icons.location_on, alert.locationName!),
                  _metaChip(
                    Icons.priority_high,
                    alert.priority.name.toUpperCase(),
                  ),
                ],
              ),
              if (alert.status != AlertStatus.resolved) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (alert.status == AlertStatus.active)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _updateStatus(alert, AlertStatus.acknowledged),
                          icon: const Icon(Icons.visibility),
                          label: const Text('Acknowledge'),
                        ),
                      ),
                    if (alert.status == AlertStatus.active)
                      const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _updateStatus(alert, AlertStatus.resolved),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Resolve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill(AlertStatus status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: AppTheme.caption),
        ],
      ),
    );
  }

  Future<void> _updateStatus(Alert alert, AlertStatus status) async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    await _alertService.updateAlertStatus(
      alert.id,
      status,
      updatedBy: user?.name,
    );
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Alert marked ${status.name}')));
  }

  void _showAlertDetails(Alert alert) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(alert.title, style: AppTheme.heading3),
              const SizedBox(height: 8),
              Text(alert.message, style: AppTheme.body1),
              const SizedBox(height: 16),
              _detailRow('Status', alert.status.name),
              _detailRow('Priority', alert.priority.name),
              if (alert.guardName != null)
                _detailRow('Guard', alert.guardName!),
              if (alert.locationName != null)
                _detailRow('Location', alert.locationName!),
              _detailRow('Created', _formatDateTime(alert.createdAt)),
              if (alert.acknowledgedBy != null)
                _detailRow('Acknowledged by', alert.acknowledgedBy!),
              if (alert.resolvedBy != null)
                _detailRow('Resolved by', alert.resolvedBy!),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: AppTheme.caption)),
          Expanded(child: Text(value, style: AppTheme.subtitle2)),
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

  IconData _priorityIcon(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.critical:
        return Icons.emergency;
      case AlertPriority.high:
        return Icons.warning;
      case AlertPriority.medium:
        return Icons.info;
      case AlertPriority.low:
        return Icons.check_circle;
    }
  }

  Color _statusColor(AlertStatus status) {
    switch (status) {
      case AlertStatus.active:
        return AppTheme.errorColor;
      case AlertStatus.acknowledged:
        return AppTheme.warningColor;
      case AlertStatus.resolved:
        return AppTheme.successColor;
      case AlertStatus.dismissed:
        return AppTheme.textSecondary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} $hour:$minute';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified,
              size: 54,
              color: AppTheme.successColor.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 12),
            Text('No alerts match this view', style: AppTheme.heading3),
            const SizedBox(height: 6),
            Text(
              'Critical and patrol alerts will appear here as soon as reports are submitted.',
              textAlign: TextAlign.center,
              style: AppTheme.body2,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTheme.body2,
        ),
      ),
    );
  }
}
