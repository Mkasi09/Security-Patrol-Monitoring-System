import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/enhanced_report.dart';
import '../models/report.dart';
import '../services/enhanced_report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_drawer.dart';

class EnhancedReportScreen extends StatefulWidget {
  const EnhancedReportScreen({super.key});

  @override
  State<EnhancedReportScreen> createState() => _EnhancedReportScreenState();
}

class _EnhancedReportScreenState extends State<EnhancedReportScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final EnhancedReportService _reportService = EnhancedReportService();
  
  // Filters
  ReportType _selectedReportType = ReportType.daily;
  DateTime? _selectedDate;
  int? _selectedYear;
  int? _selectedMonth;
  bool _isLoading = false;
  
  // Data
  DailyReport? _currentDailyReport;
  MonthlyReport? _currentMonthlyReport;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      // Just check if service is working
      await _reportService.getMonthlyReports();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load reports: $e');
    }
  }

  Future<void> _generateReport() async {
    if (_selectedReportType == ReportType.daily && _selectedDate == null) {
      _showErrorSnackBar('Please select a date for daily report');
      return;
    }
    
    if (_selectedReportType == ReportType.monthly && (_selectedYear == null || _selectedMonth == null)) {
      _showErrorSnackBar('Please select year and month for monthly report');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      if (_selectedReportType == ReportType.daily) {
        final report = await _reportService.generateDailyReport(_selectedDate!);
        setState(() {
          _currentDailyReport = report;
          _currentMonthlyReport = null;
        });
      } else {
        final report = await _reportService.generateMonthlyReport(_selectedYear!, _selectedMonth!);
        setState(() {
          _currentMonthlyReport = report;
          _currentDailyReport = null;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to generate report: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportToCSV() async {
    if (_currentDailyReport == null && _currentMonthlyReport == null) {
      _showErrorSnackBar('Please generate a report first');
      return;
    }

    try {
      String csvContent;
      if (_currentDailyReport != null) {
        csvContent = await _reportService.exportDailyReportToCSV(_currentDailyReport!);
      } else {
        csvContent = await _reportService.exportMonthlyReportToCSV(_currentMonthlyReport!);
      }

      // Save to file (simplified - in real app you'd use file_picker)
      final buffer = StringBuffer();
      buffer.write(csvContent);
      
      // Copy to clipboard for now
      await Clipboard.setData(ClipboardData(text: csvContent));
      _showSuccessSnackBar('Report copied to clipboard! Paste it into a text editor and save as .csv');
    } catch (e) {
      _showErrorSnackBar('Failed to export report: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(
        title: 'Advanced Reports',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          // Report Type Selector and Filters
          _buildReportFilters(),
          
          // Generate Button
          _buildGenerateButton(),
          
          // Export Button
          if (_currentDailyReport != null || _currentMonthlyReport != null)
            _buildExportButton(),
          
          // Report Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildReportContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Configuration',
            style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Report Type Selection
          Row(
            children: [
              Expanded(
                child: RadioListTile<ReportType>(
                  title: const Text('Daily Report'),
                  value: ReportType.daily,
                  groupValue: _selectedReportType,
                  onChanged: (value) {
                    setState(() => _selectedReportType = value!);
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<ReportType>(
                  title: const Text('Monthly Report'),
                  value: ReportType.monthly,
                  groupValue: _selectedReportType,
                  onChanged: (value) {
                    setState(() => _selectedReportType = value!);
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Date/Period Selection
          if (_selectedReportType == ReportType.daily) ...[
            ListTile(
              title: const Text('Select Date'),
              subtitle: Text(_selectedDate?.toString().split(' ')[0] ?? 'No date selected'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),
          ] else ...[
            ListTile(
              title: const Text('Select Year'),
              subtitle: Text(_selectedYear?.toString() ?? 'No year selected'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectYear,
            ),
            ListTile(
              title: const Text('Select Month'),
              subtitle: Text(_selectedMonth != null ? _getMonthName(_selectedMonth!) : 'No month selected'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectMonth,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: _generateReport,
        icon: const Icon(Icons.analytics),
        label: const Text('Generate Report'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _exportToCSV,
        icon: const Icon(Icons.download),
        label: const Text('Export to CSV'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    if (_currentDailyReport != null) {
      return _buildDailyReportView(_currentDailyReport!);
    } else if (_currentMonthlyReport != null) {
      return _buildMonthlyReportView(_currentMonthlyReport!);
    } else {
      return _buildEmptyState();
    }
  }

  Widget _buildDailyReportView(DailyReport report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report Header
          _buildReportHeader(
            'Daily Report',
            report.date.toString().split(' ')[0],
            report.generatedAt.toString().split('.')[0],
          ),
          
          const SizedBox(height: 16),
          
          // Summary Cards
          _buildSummaryCards(report.summary),
          
          const SizedBox(height: 16),
          
          // Status Breakdown
          _buildStatusBreakdown(report.summary.statusBreakdown),
          
          const SizedBox(height: 16),
          
          // Top Performers
          _buildTopPerformers(report.summary.topPerformers),
          
          const SizedBox(height: 16),
          
          // Patrol Reports
          _buildPatrolReports(report.patrolReports),
          
          const SizedBox(height: 16),
          
          // Critical Alerts
          if (report.summary.criticalAlerts.isNotEmpty)
            _buildCriticalAlerts(report.summary.criticalAlerts),
        ],
      ),
    );
  }

  Widget _buildMonthlyReportView(MonthlyReport report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report Header
          _buildReportHeader(
            'Monthly Report',
            '${_getMonthName(report.month)} ${report.year}',
            report.generatedAt.toString().split('.')[0],
          ),
          
          const SizedBox(height: 16),
          
          // Monthly Summary
          _buildMonthlySummary(report.monthlySummary),
          
          const SizedBox(height: 16),
          
          // Trend Analysis
          _buildTrendAnalysis(report.trends),
          
          const SizedBox(height: 16),
          
          // Daily Breakdown
          _buildDailyBreakdown(report.dailyReports),
          
          const SizedBox(height: 16),
          
          // Top Performers
          _buildTopPerformers(report.monthlySummary.monthlyTopPerformers),
        ],
      ),
    );
  }

  Widget _buildReportHeader(String title, String period, String generatedAt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.heading2.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Period: $period',
            style: AppTheme.body1.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            'Generated: $generatedAt',
            style: AppTheme.body2.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ReportSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total Patrols',
                value: summary.totalPatrols.toString(),
                icon: Icons.security,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Unique Locations',
                value: summary.uniqueLocations.toString(),
                icon: Icons.location_on,
                color: AppTheme.infoColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Active Guards',
                value: summary.activeGuards.toString(),
                icon: Icons.people,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Critical Alerts',
                value: summary.criticalAlerts.length.toString(),
                icon: Icons.warning,
                color: AppTheme.errorColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBreakdown(Map<String, int> statusBreakdown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Breakdown',
          style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...statusBreakdown.entries.map((entry) {
          Color color;
          switch (entry.key) {
            case 'all_clear':
              color = Colors.green;
              break;
            case 'suspicious':
              color = Colors.orange;
              break;
            case 'emergency':
              color = Colors.red;
              break;
            default:
              color = Colors.grey;
          }
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.key.toUpperCase(),
                    style: AppTheme.body2.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  entry.value.toString(),
                  style: AppTheme.body2.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTopPerformers(List<String> topPerformers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Performers',
          style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...topPerformers.map((performer) => ListTile(
          leading: const Icon(Icons.emoji_events, color: Colors.amber),
          title: Text(performer),
          dense: true,
        )),
      ],
    );
  }

  Widget _buildPatrolReports(List<Report> reports) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Patrol Reports (${reports.length})',
          style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...reports.take(10).map((report) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('${report.userName} - ${report.locationName}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.timestamp.toString().split('.')[0]),
                Text('Status: ${report.status.toUpperCase()}'),
                if (report.notes.isNotEmpty) Text('Notes: ${report.notes}'),
              ],
            ),
            trailing: _getStatusIcon(report.status),
          ),
        )),
        if (reports.length > 10)
          TextButton(
            onPressed: () {
              // Show all reports in a separate screen
            },
            child: Text('View all ${reports.length} reports'),
          ),
      ],
    );
  }

  Widget _buildCriticalAlerts(List<String> alerts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Critical Alerts',
          style: AppTheme.heading3.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.errorColor,
          ),
        ),
        const SizedBox(height: 12),
        ...alerts.map((alert) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: AppTheme.errorColor.withValues(alpha: 0.1),
          child: ListTile(
            leading: const Icon(Icons.warning, color: AppTheme.errorColor),
            title: Text(alert),
            dense: true,
          ),
        )),
      ],
    );
  }

  Widget _buildMonthlySummary(MonthlySummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Summary',
          style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total Patrols',
                value: summary.totalPatrols.toString(),
                icon: Icons.security,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Avg Daily Patrols',
                value: summary.averageDailyPatrols.toStringAsFixed(1),
                icon: Icons.trending_up,
                color: AppTheme.infoColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total Locations',
                value: summary.totalLocations.toString(),
                icon: Icons.location_on,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Total Guards',
                value: summary.totalGuards.toString(),
                icon: Icons.people,
                color: AppTheme.warningColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrendAnalysis(List<TrendAnalysis> trends) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trend Analysis',
          style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...trends.map((trend) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(trend.metric),
            subtitle: Text('Trend: ${trend.trendPercentage.toStringAsFixed(1)}%'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _getTrendIcon(trend.trendDirection),
                const SizedBox(width: 8),
                Text(
                  trend.trendDirection.toUpperCase(),
                  style: AppTheme.caption.copyWith(
                    color: _getTrendColor(trend.trendDirection),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildDailyBreakdown(List<DailyReport> dailyReports) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Breakdown',
          style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...dailyReports.map((daily) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(daily.date.toString().split(' ')[0]),
            subtitle: Text(
              'Patrols: ${daily.summary.totalPatrols} | Locations: ${daily.summary.uniqueLocations} | Guards: ${daily.summary.activeGuards}'
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              setState(() {
                _currentDailyReport = daily;
                _currentMonthlyReport = null;
              });
            },
          ),
        )),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Report Generated',
            style: AppTheme.heading3.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select report type and period, then click "Generate Report"',
            style: AppTheme.body2.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _SummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.heading2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTheme.caption.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'all_clear':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'suspicious':
        return const Icon(Icons.warning, color: Colors.orange);
      case 'emergency':
        return const Icon(Icons.error, color: Colors.red);
      default:
        return const Icon(Icons.help, color: Colors.grey);
    }
  }

  Widget _getTrendIcon(String direction) {
    switch (direction) {
      case 'up':
        return const Icon(Icons.trending_up, color: Colors.green);
      case 'down':
        return const Icon(Icons.trending_down, color: Colors.red);
      default:
        return const Icon(Icons.trending_flat, color: Colors.grey);
    }
  }

  Color _getTrendColor(String direction) {
    switch (direction) {
      case 'up':
        return Colors.green;
      case 'down':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectYear() async {
    final year = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Year'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              final year = DateTime.now().year - index;
              return ListTile(
                title: Text(year.toString()),
                onTap: () => Navigator.pop(context, year),
              );
            },
          ),
        ),
      ),
    );
    if (year != null) {
      setState(() => _selectedYear = year);
    }
  }

  Future<void> _selectMonth() async {
    final month = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Month'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: ListView.builder(
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              return ListTile(
                title: Text(_getMonthName(month)),
                onTap: () => Navigator.pop(context, month),
              );
            },
          ),
        ),
      ),
    );
    if (month != null) {
      setState(() => _selectedMonth = month);
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

enum ReportType {
  daily,
  monthly,
}
