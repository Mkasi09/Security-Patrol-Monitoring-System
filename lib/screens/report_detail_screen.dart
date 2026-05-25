import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/report.dart';
import '../theme/app_theme.dart';

class ReportDetailScreen extends StatelessWidget {
  final Report report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(report.status);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Report Details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _heroCard(color),
          const SizedBox(height: 14),
          _section(
            title: 'Report Information',
            icon: Icons.assignment,
            children: [
              _infoRow('Guard', report.userName),
              _infoRow('Location', report.locationName),
              _infoRow(
                'Submitted',
                DateFormat('MMM dd, yyyy - HH:mm').format(report.timestamp),
              ),
              _infoRow('Report age', _reportAge(report.timestamp)),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Notes',
            icon: Icons.notes,
            children: [
              Text(
                report.notes.isEmpty ? 'No notes provided' : report.notes,
                style: AppTheme.body1.copyWith(height: 1.35),
              ),
            ],
          ),
          if (report.imageUrl != null) ...[
            const SizedBox(height: 12),
            _imageSection(),
          ],
          const SizedBox(height: 12),
          _section(
            title: 'Location Data',
            icon: Icons.location_on,
            children: [
              _infoRow('Latitude', report.latitude.toStringAsFixed(6)),
              _infoRow('Longitude', report.longitude.toStringAsFixed(6)),
              _infoRow('Location ID', report.locationId),
              _infoRow('Report ID', report.id),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_statusIcon(report.status), color: color, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusText(report.status),
                  style: AppTheme.heading3.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  report.locationName,
                  style: AppTheme.body2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: AppTheme.subtitle1),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _imageSection() {
    return _section(
      title: 'Evidence Photo',
      icon: Icons.image,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.network(
              report.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade100,
                  child: const Center(child: Text('Image not available')),
                );
              },
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 104, child: Text(label, style: AppTheme.caption)),
          Expanded(child: Text(value, style: AppTheme.subtitle2)),
        ],
      ),
    );
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

  String _reportAge(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}
