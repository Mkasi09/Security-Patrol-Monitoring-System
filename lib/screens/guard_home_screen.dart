import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_navigation_drawer.dart';
import '../widgets/modern_bottom_navigation.dart';
import '../widgets/modern_app_bar.dart';
import '../models/report.dart';
import 'qr_scanner_screen.dart';
import 'report_screen.dart';
import 'patrol_history_screen.dart';
import 'profile_screen.dart';

class GuardHomeScreen extends StatefulWidget {
  const GuardHomeScreen({super.key});

  @override
  State<GuardHomeScreen> createState() => _GuardHomeScreenState();
}

class _GuardHomeScreenState extends State<GuardHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  int _currentIndex = 0;
  late PageController _pageController;
  
  // Data state
  List<Report> _recentReports = [];
  Map<String, int> _statistics = {
    'today': 0,
    'week': 0,
    'total': 0,
  };
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _loadHomeData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Load home screen data
  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      
      if (userId != null) {
        // Fetch recent reports
        final reports = await _firestoreService.getReportsByUserId(userId);
        
        // Calculate statistics
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        
        int todayCount = 0;
        int weekCount = 0;
        
        for (final report in reports) {
          if (report.timestamp.isAfter(today)) {
            todayCount++;
          }
          if (report.timestamp.isAfter(weekStart)) {
            weekCount++;
          }
        }
        
        setState(() {
          _recentReports = reports.take(5).toList(); // Show last 5 reports
          _statistics = {
            'today': todayCount,
            'week': weekCount,
            'total': reports.length,
          };
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  /// 🔥 Central Scan Logic (NO duplication anymore)
  Future<void> _startScanFlow() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );

    if (result != null && mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final location =
      await _firestoreService.getLocationByQRCode(result);

      if (!mounted) return;

      Navigator.pop(context); // close loading

      if (location != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportScreen(
              locationId: location.id,
              locationName: location.name,
              qrCode: result,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            const Text('Invalid QR code. Location not registered.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.backgroundColor,
      appBar: ModernAppBar(
        title: _currentIndex == 2 ? 'Patrol History' : 'Guard Dashboard',
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: ModernNavigationDrawer(
        currentPage: 'home',
        userRole: 'guard',
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: [
          /// 🏠 HOME TAB
          RefreshIndicator(
            onRefresh: _loadHomeData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(),
                  const SizedBox(height: 24),

                  _buildStatsSection(),
                  const SizedBox(height: 24),

                  Text('Quick Actions', style: AppTheme.heading3),
                  const SizedBox(height: 16),

                  _buildActionCardsGrid(),
                  const SizedBox(height: 24),

                  Text('Recent Activity', style: AppTheme.heading3),
                  const SizedBox(height: 16),

                  _buildRecentActivitySection(),
                ],
              ),
            ),
          ),

          /// 📷 SCAN TAB
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text('QR Scanner', style: AppTheme.heading3),
                const SizedBox(height: 8),
                Text(
                  'Scan QR code at the site to submit a report',
                  style: AppTheme.body2,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _startScanFlow,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Start Scanning'),
                ),
              ],
            ),
          ),

          /// 📜 HISTORY TAB
          const PatrolHistoryScreen(),

          /// 👤 PROFILE TAB
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: ModernBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }

  Widget _comingSoonTab({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(title, style: AppTheme.heading3),
          const SizedBox(height: 8),
          Text(description, style: AppTheme.body2),
          const SizedBox(height: 32),
          Text('Coming soon', style: AppTheme.caption),
        ],
      ),
    );
  }

  /// 🔹 WELCOME CARD
  Widget _buildWelcomeCard() {
    final authProvider = Provider.of<AuthProvider>(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.security, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome back',
                    style: TextStyle(color: Colors.white70)),
                Text(
                  authProvider.currentUser?.name ?? "Guard",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const Text(
                  'You are on active patrol',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 STATS
  Widget _buildStatsSection() {
    if (_isLoading) {
      return Row(
        children: [
          Expanded(child: _buildLoadingStatCard()),
          const SizedBox(width: 12),
          Expanded(child: _buildLoadingStatCard()),
          const SizedBox(width: 12),
          Expanded(child: _buildLoadingStatCard()),
        ],
      );
    }
    
    return Row(
      children: [
        Expanded(child: _buildStatCard("Today's Patrols", _statistics['today'].toString())),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard("This Week", _statistics['week'].toString())),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard("Reports", _statistics['total'].toString())),
      ],
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }

  Widget _buildLoadingStatCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 ACTIONS
  Widget _buildActionCardsGrid() {
    return Column(
      children: [
        _buildPrimaryActionCard(
          title: 'Scan Location',
          description: 'Scan QR code to start patrol',
          onTap: _startScanFlow,
        ),
      ],
    );
  }

  Widget _buildPrimaryActionCard({
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.qr_code_scanner, color: Colors.white),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.white)),
                Text(description,
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 ACTIVITY
  Widget _buildRecentActivitySection() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildLoadingActivityItem(),
            _buildLoadingActivityItem(),
            _buildLoadingActivityItem(),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
              const SizedBox(height: 12),
              Text(
                'Error loading activity',
                style: AppTheme.heading3.copyWith(color: AppTheme.errorColor),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTheme.body2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_recentReports.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No patrol activity yet\nScan your first location to begin',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._recentReports.map((report) => _buildActivityItem(report)),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() => _currentIndex = 2);
                _pageController.animateToPage(
                  2,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('View All History'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Report report) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(report.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(report.status),
              color: _getStatusColor(report.status),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      report.locationName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(report.timestamp),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  report.notes.isNotEmpty ? report.notes : 'No notes',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingActivityItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'all_clear':
        return Colors.green;
      case 'suspicious':
        return Colors.orange;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'all_clear':
        return Icons.check_circle;
      case 'suspicious':
        return Icons.warning;
      case 'emergency':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}