import 'package:flutter/material.dart';
import '../models/report.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_drawer.dart';
import 'report_detail_screen.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _statusFilter = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AdminAppBar(
        title: 'Reports',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<Report>>(
        future: _firestoreService.getAllReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load reports: ${snapshot.error}'),
            );
          }

          final reports = _filterReports(snapshot.data ?? []);
          return Column(
            children: [
              _buildFilters(),
              Expanded(
                child: reports.isEmpty
                    ? const Center(child: Text('No reports match this view'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: reports.length,
                        itemBuilder: (context, index) =>
                            _buildReportCard(reports[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search reports, guards, locations, or notes',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', 'all'),
                _filterChip('All Clear', 'all_clear'),
                _filterChip('Suspicious', 'suspicious'),
                _filterChip('Emergency', 'emergency'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _statusFilter == value,
        onSelected: (_) => setState(() => _statusFilter = value),
      ),
    );
  }

  List<Report> _filterReports(List<Report> reports) {
    return reports.where((report) {
      if (_statusFilter != 'all' && report.status != _statusFilter) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return report.userName.toLowerCase().contains(query) ||
          report.locationName.toLowerCase().contains(query) ||
          report.notes.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildReportCard(Report report) {
    final color = _statusColor(report.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(_statusIcon(report.status), color: color),
        ),
        title: Text(
          report.locationName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${report.userName} - ${_formatTime(report.timestamp)}\n${report.notes.isEmpty ? 'No notes' : report.notes}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
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
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'emergency':
        return AppTheme.errorColor;
      case 'suspicious':
        return AppTheme.warningColor;
      default:
        return AppTheme.successColor;
    }
  }

  IconData _statusIcon(String status) {
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
