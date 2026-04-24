import 'dart:async';
import 'package:flutter/foundation.dart';
import 'enhanced_report_service.dart';

class ReportSchedulerService {
  static final ReportSchedulerService _instance = ReportSchedulerService._internal();
  factory ReportSchedulerService() => _instance;
  ReportSchedulerService._internal();

  final EnhancedReportService _reportService = EnhancedReportService();
  Timer? _monthlyTimer;

  /// Start the monthly report scheduler
  void startMonthlyScheduler() {
    // Cancel any existing timer
    stopMonthlyScheduler();

    // Calculate time until next month
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final timeUntilNextMonth = nextMonth.difference(now);

    debugPrint('Monthly report scheduler started. Next report in: ${timeUntilNextMonth.inDays} days');

    // Schedule the first run for the beginning of next month
    Timer(timeUntilNextMonth, () {
      _generateMonthlyReport();
      // Then schedule it to run every month
      _startRecurringMonthlySchedule();
    });

    // Also check if we need to generate a report for the previous month
    _checkForMissingMonthlyReport();
  }

  /// Stop the monthly report scheduler
  void stopMonthlyScheduler() {
    _monthlyTimer?.cancel();
    _monthlyTimer = null;
  }

  /// Start recurring monthly schedule
  void _startRecurringMonthlySchedule() {
    const monthlyInterval = Duration(days: 30); // Approximate month length
    _monthlyTimer = Timer.periodic(monthlyInterval, (_) {
      _generateMonthlyReport();
    });
    debugPrint('Recurring monthly report scheduler started');
  }

  /// Generate monthly report for the previous month
  Future<void> _generateMonthlyReport() async {
    try {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      
      debugPrint('Generating monthly report for: ${lastMonth.month}/${lastMonth.year}');
      
      await _reportService.autoGenerateMonthlyReport();
      
      debugPrint('Monthly report generated successfully for: ${lastMonth.month}/${lastMonth.year}');
    } catch (e) {
      debugPrint('Failed to generate monthly report: $e');
    }
  }

  /// Check if we need to generate a report for the previous month
  Future<void> _checkForMissingMonthlyReport() async {
    try {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      
      // Check if monthly report for last month exists
      final monthlyReports = await _reportService.getMonthlyReports(year: lastMonth.year);
      final lastMonthReport = monthlyReports.where((r) => r.month == lastMonth.month).toList();
      
      if (lastMonthReport.isEmpty) {
        debugPrint('Missing monthly report for ${lastMonth.month}/${lastMonth.year}. Generating now...');
        await _generateMonthlyReport();
      } else {
        debugPrint('Monthly report for ${lastMonth.month}/${lastMonth.year} already exists');
      }
    } catch (e) {
      debugPrint('Error checking for missing monthly report: $e');
    }
  }

  /// Manually trigger monthly report generation for a specific month
  Future<void> generateMonthlyReport(int year, int month) async {
    try {
      debugPrint('Manually generating monthly report for: $month/$year');
      await _reportService.generateMonthlyReport(year, month);
      debugPrint('Manual monthly report generation completed');
    } catch (e) {
      debugPrint('Failed to generate manual monthly report: $e');
      rethrow;
    }
  }

  /// Get scheduler status
  Map<String, dynamic> getSchedulerStatus() {
    return {
      'isRunning': _monthlyTimer?.isActive ?? false,
      'nextRun': _monthlyTimer?.tick != null ? 'In ${_monthlyTimer!.tick} ticks' : 'Not scheduled',
    };
  }
}
