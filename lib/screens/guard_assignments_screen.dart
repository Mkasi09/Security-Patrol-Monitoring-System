import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patrol_shift.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class GuardAssignmentsScreen extends StatelessWidget {
  final VoidCallback onStartScan;

  const GuardAssignmentsScreen({super.key, required this.onStartScan});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    if (user == null) {
      return const Center(child: Text('Sign in again to view assignments.'));
    }

    return StreamBuilder<List<PatrolShift>>(
      stream: FirestoreService().streamPatrolShiftsByGuard(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _MessageState(
            icon: Icons.error_outline,
            title: 'Assignments unavailable',
            message: snapshot.error.toString(),
          );
        }

        final shifts = snapshot.data ?? [];
        final visibleShifts = _visibleShifts(shifts);

        if (visibleShifts.isEmpty) {
          return _MessageState(
            icon: Icons.event_available,
            title: 'No assignments yet',
            message: 'Your manager has not assigned patrols for this period.',
            action: ElevatedButton.icon(
              onPressed: onStartScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Location'),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _buildHeader(visibleShifts),
              const SizedBox(height: 16),
              ...visibleShifts.map(
                (shift) => _buildAssignmentCard(context, shift),
              ),
            ],
          ),
        );
      },
    );
  }

  List<PatrolShift> _visibleShifts(List<PatrolShift> shifts) {
    final now = DateTime.now();
    final startWindow = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    final endWindow = startWindow.add(const Duration(days: 14));

    return shifts.where((shift) {
      return shift.startsAt.isAfter(startWindow) &&
          shift.startsAt.isBefore(endWindow);
    }).toList();
  }

  Widget _buildHeader(List<PatrolShift> shifts) {
    final now = DateTime.now();
    final dueNow = shifts.where((shift) {
      return shift.status == 'scheduled' &&
          shift.startsAt.isBefore(now) &&
          shift.endsAt.isAfter(now);
    }).length;
    final upcoming = shifts.where((shift) {
      return shift.status == 'scheduled' && shift.startsAt.isAfter(now);
    }).length;
    final completed = shifts
        .where((shift) => shift.status == 'completed')
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _summary('Now', dueNow),
          _divider(),
          _summary('Next', upcoming),
          _divider(),
          _summary('Done', completed),
        ],
      ),
    );
  }

  Widget _summary(String label, int value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 36, color: Colors.white24);
  }

  Widget _buildAssignmentCard(BuildContext context, PatrolShift shift) {
    final status = _effectiveStatus(shift);
    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_statusIcon(status), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shift.locationName, style: AppTheme.subtitle1),
                      const SizedBox(height: 4),
                      Text(_formatRange(shift), style: AppTheme.body2),
                    ],
                  ),
                ),
                _statusPill(status, color),
              ],
            ),
            if (shift.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(shift.notes, style: AppTheme.body2),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onStartScan,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: status == 'completed'
                        ? null
                        : () => _markComplete(context, shift),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markComplete(BuildContext context, PatrolShift shift) async {
    await FirestoreService().updatePatrolShiftStatus(shift.id, 'completed');
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Assignment marked complete')));
  }

  Widget _statusPill(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _effectiveStatus(PatrolShift shift) {
    if (shift.status == 'scheduled' && shift.endsAt.isBefore(DateTime.now())) {
      return 'missed';
    }
    if (shift.status == 'scheduled' &&
        shift.startsAt.isBefore(DateTime.now()) &&
        shift.endsAt.isAfter(DateTime.now())) {
      return 'active';
    }
    return shift.status;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppTheme.warningColor;
      case 'completed':
        return AppTheme.successColor;
      case 'missed':
        return AppTheme.errorColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.directions_run;
      case 'completed':
        return Icons.verified;
      case 'missed':
        return Icons.error;
      default:
        return Icons.schedule;
    }
  }

  String _formatRange(PatrolShift shift) {
    return '${_formatDate(shift.startsAt)}  ${_formatTime(shift.startsAt)} - ${_formatTime(shift.endsAt)}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppTheme.primaryColor.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTheme.heading3, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: AppTheme.body2, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
