import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/report.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'report_detail_screen.dart';

class PatrolHistoryScreen extends StatefulWidget {
  const PatrolHistoryScreen({super.key});

  @override
  State<PatrolHistoryScreen> createState() => _PatrolHistoryScreenState();
}

class _PatrolHistoryScreenState extends State<PatrolHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Report> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).currentUser;
      if (user == null) throw Exception('User not authenticated');
      final reports = await _firestoreService.getReportsByUserId(user.id);
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load reports: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleReports = _filteredReports();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReports,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              _buildFilters(),
              const SizedBox(height: 14),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                _messageState(
                  Icons.error_outline,
                  'Unable to load history',
                  _errorMessage!,
                )
              else if (visibleReports.isEmpty)
                _messageState(
                  Icons.history,
                  'No reports found',
                  'Reports matching this filter will appear here.',
                )
              else
                ...visibleReports.map(_buildReportCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final todayCount = _reports.where((report) {
      final now = DateTime.now();
      return report.timestamp.year == now.year &&
          report.timestamp.month == now.month &&
          report.timestamp.day == now.day;
    }).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _summary('Today', todayCount, AppTheme.primaryColor),
          _divider(),
          _summary('Total', _reports.length, AppTheme.secondaryColor),
          _divider(),
          _summary(
            'Alerts',
            _reports.where((r) => r.status != 'all_clear').length,
            AppTheme.warningColor,
          ),
        ],
      ),
    );
  }

  Widget _summary(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(label, style: AppTheme.caption),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 34, color: Colors.grey.shade200);

  Widget _buildFilters() {
    final filters = {
      'all': 'All',
      'all_clear': 'Clear',
      'suspicious': 'Suspicious',
      'emergency': 'Emergency',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(entry.value),
              selected: _selectedStatus == entry.key,
              onSelected: (_) => setState(() => _selectedStatus = entry.key),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    final color = _statusColor(report.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportDetailScreen(report: report),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_statusIcon(report.status), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            report.locationName,
                            style: AppTheme.subtitle1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (report.imageUrl != null)
                          const Icon(
                            Icons.image,
                            size: 18,
                            color: AppTheme.secondaryColor,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusText(report.status),
                      style: TextStyle(color: color),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'MMM dd, yyyy - HH:mm',
                      ).format(report.timestamp),
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _messageState(IconData icon, String title, String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(icon, size: 58, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          Text(title, style: AppTheme.heading3, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message, style: AppTheme.body2, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  List<Report> _filteredReports() {
    if (_selectedStatus == 'all') return _reports;
    return _reports
        .where((report) => report.status == _selectedStatus)
        .toList();
  }

  String _statusText(String status) {
    switch (status) {
      case 'all_clear':
        return 'All Clear';
      case 'suspicious':
        return 'Suspicious Activity';
      case 'emergency':
        return 'Emergency';
      default:
        return 'Unknown';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'all_clear':
        return AppTheme.successColor;
      case 'suspicious':
        return AppTheme.warningColor;
      case 'emergency':
        return AppTheme.errorColor;
      default:
        return AppTheme.infoColor;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'all_clear':
        return Icons.check_circle;
      case 'suspicious':
        return Icons.warning;
      case 'emergency':
        return Icons.emergency;
      default:
        return Icons.info;
    }
  }
}
