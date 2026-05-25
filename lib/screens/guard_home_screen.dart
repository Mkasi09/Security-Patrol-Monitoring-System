import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patrol_shift.dart';
import '../models/report.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/modern_bottom_navigation.dart';
import '../widgets/modern_navigation_drawer.dart';
import 'guard_assignments_screen.dart';
import 'patrol_history_screen.dart';
import 'profile_screen.dart';
import 'qr_scanner_screen.dart';
import 'report_screen.dart';

class GuardHomeScreen extends StatefulWidget {
  const GuardHomeScreen({super.key});

  @override
  State<GuardHomeScreen> createState() => _GuardHomeScreenState();
}

class _GuardHomeScreenState extends State<GuardHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  late final PageController _pageController;
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;
  List<Report> _recentReports = [];
  List<PatrolShift> _assignments = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadHomeData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final reports = await _firestoreService.getReportsByUserId(user.id);
      final assignments = await _firestoreService.getPatrolShiftsByGuard(
        user.id,
      );

      if (!mounted) return;
      setState(() {
        _recentReports = reports.take(5).toList();
        _assignments = assignments;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load guard data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _startScanFlow() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final location = await _firestoreService.getLocationByQRCode(result);
    if (!mounted) return;
    Navigator.pop(context);

    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid QR code. Location not registered.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportScreen(
          locationId: location.id,
          locationName: location.name,
          qrCode: result,
        ),
      ),
    );

    if (mounted) {
      _loadHomeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.backgroundColor,
      appBar: ModernAppBar(
        title: _pageTitle(),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const ModernNavigationDrawer(
        currentPage: 'home',
        userRole: 'guard',
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: [
            _buildHomeTab(),
            _buildScanTab(),
            GuardAssignmentsScreen(onStartScan: _startScanFlow),
            const PatrolHistoryScreen(),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: ModernBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _goToPage,
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadHomeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 18),
            _buildTodaySummary(),
            const SizedBox(height: 18),
            _buildNextAssignmentCard(),
            const SizedBox(height: 22),
            Text('Quick Actions', style: AppTheme.heading3),
            const SizedBox(height: 12),
            _buildQuickActions(),
            const SizedBox(height: 22),
            Row(
              children: [
                Text('Recent Activity', style: AppTheme.heading3),
                const Spacer(),
                TextButton(
                  onPressed: () => _goToPage(3),
                  child: const Text('View All'),
                ),
              ],
            ),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final next = _nextAssignment();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Image.asset('assets/logo1.png', height: 34, color: Colors.white),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active patrol',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  user?.name ?? 'Guard',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  next == null
                      ? 'No current assignment'
                      : 'Next: ${next.locationName}',
                  style: const TextStyle(color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummary() {
    if (_isLoading) return _loadingPanel(height: 92);

    final todayReports = _recentReports.where((report) {
      return _isSameDay(report.timestamp, DateTime.now());
    }).length;

    final scheduled = _todayAssignments().where((shift) {
      final status = _effectiveShiftStatus(shift);
      return status == 'scheduled' || status == 'active';
    }).length;
    final completed = _todayAssignments().where((shift) {
      return _effectiveShiftStatus(shift) == 'completed';
    }).length;
    final missed = _todayAssignments().where((shift) {
      return _effectiveShiftStatus(shift) == 'missed';
    }).length;

    return Row(
      children: [
        Expanded(
          child: _metricCard('Reports', todayReports, AppTheme.primaryColor),
        ),
        const SizedBox(width: 8),
        Expanded(child: _metricCard('Due', scheduled, AppTheme.warningColor)),
        const SizedBox(width: 8),
        Expanded(child: _metricCard('Done', completed, AppTheme.successColor)),
        const SizedBox(width: 8),
        Expanded(child: _metricCard('Missed', missed, AppTheme.errorColor)),
      ],
    );
  }

  Widget _metricCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(label, style: AppTheme.caption, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildNextAssignmentCard() {
    if (_isLoading) return _loadingPanel(height: 170);

    final next = _nextAssignment();
    if (next == null) {
      return _emptyPanel(
        icon: Icons.event_available,
        title: 'No active assignment',
        message:
            'Assigned patrols will appear here as soon as a manager schedules them.',
        action: OutlinedButton.icon(
          onPressed: () => _goToPage(2),
          icon: const Icon(Icons.event_note),
          label: const Text('Open Tasks'),
        ),
      );
    }

    final status = _effectiveShiftStatus(next);
    final color = _shiftColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, color: color),
              const SizedBox(width: 8),
              Text('Next Patrol', style: AppTheme.heading3),
              const Spacer(),
              _pill(status, color),
            ],
          ),
          const SizedBox(height: 12),
          Text(next.locationName, style: AppTheme.subtitle1),
          const SizedBox(height: 4),
          Text(_shiftTime(next), style: AppTheme.body2),
          if (next.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(next.notes, style: AppTheme.body2),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startScanFlow,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _goToPage(2),
                  icon: const Icon(Icons.event_note),
                  label: const Text('Tasks'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        InkWell(
          onTap: _startScanFlow,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.qr_code_scanner, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Scan Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _smallAction(
                Icons.warning,
                'Suspicious',
                AppTheme.warningColor,
                _startScanFlow,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _smallAction(
                Icons.emergency,
                'Emergency',
                AppTheme.errorColor,
                _startScanFlow,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _smallAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(label, style: AppTheme.subtitle2),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_isLoading) return _loadingPanel(height: 150);
    if (_error != null) {
      return _emptyPanel(
        icon: Icons.error_outline,
        title: 'Could not load activity',
        message: _error!,
      );
    }
    if (_recentReports.isEmpty) {
      return _emptyPanel(
        icon: Icons.history,
        title: 'No patrol activity yet',
        message: 'Scan your first location to begin your patrol history.',
      );
    }

    return Column(
      children: _recentReports.map((report) {
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
              report.notes.isEmpty
                  ? _formatRelative(report.timestamp)
                  : report.notes,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: report.imageUrl != null
                ? const Icon(Icons.image, color: AppTheme.secondaryColor)
                : Text(
                    _formatRelative(report.timestamp),
                    style: AppTheme.caption,
                  ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScanTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 88,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text('Scan Checkpoint', style: AppTheme.heading3),
            const SizedBox(height: 8),
            Text(
              'Scan the QR code at a checkpoint to submit a patrol report.',
              textAlign: TextAlign.center,
              style: AppTheme.body2,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startScanFlow,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Start Scanning'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyPanel({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 42),
          const SizedBox(height: 10),
          Text(title, style: AppTheme.subtitle1, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message, style: AppTheme.body2, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 14), action],
        ],
      ),
    );
  }

  Widget _loadingPanel({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  String _pageTitle() {
    switch (_currentIndex) {
      case 1:
        return 'Scan Checkpoint';
      case 2:
        return 'Assignments';
      case 3:
        return 'Patrol History';
      case 4:
        return 'Profile';
      default:
        return 'Guard Dashboard';
    }
  }

  void _goToPage(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  List<PatrolShift> _todayAssignments() {
    final now = DateTime.now();
    return _assignments
        .where((shift) => _isSameDay(shift.startsAt, now))
        .toList();
  }

  PatrolShift? _nextAssignment() {
    final now = DateTime.now();
    final active = _assignments.where((shift) {
      return shift.status == 'scheduled' &&
          shift.startsAt.isBefore(now) &&
          shift.endsAt.isAfter(now);
    }).toList();
    if (active.isNotEmpty) return active.first;

    final upcoming = _assignments.where((shift) {
      return shift.status == 'scheduled' && shift.startsAt.isAfter(now);
    }).toList();
    upcoming.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  String _effectiveShiftStatus(PatrolShift shift) {
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

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _shiftColor(String status) {
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _shiftTime(PatrolShift shift) {
    return '${_dateLabel(shift.startsAt)} ${_clock(shift.startsAt)} - ${_clock(shift.endsAt)}';
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, now.add(const Duration(days: 1)))) return 'Tomorrow';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _clock(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatRelative(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${dateTime.day}/${dateTime.month}';
  }
}
