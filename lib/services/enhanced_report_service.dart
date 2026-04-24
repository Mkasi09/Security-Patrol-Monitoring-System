import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enhanced_report.dart';
import '../models/report.dart';
import '../models/user.dart';
import '../models/location.dart';
import 'firestore_service.dart';

class EnhancedReportService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate a comprehensive daily report
  Future<DailyReport> generateDailyReport(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      // Get all data for the day
      final allReports = await _firestoreService.getAllReports();
      final reports = allReports.where((r) => 
        r.timestamp.isAfter(startOfDay) && r.timestamp.isBefore(endOfDay)
      ).toList();
      final locations = await _firestoreService.getAllLocations();
      final users = await _firestoreService.getAllUsers();

      // Filter activities for the specific day
      final locationsAdded = _filterLocationsByDate(locations, startOfDay, endOfDay);
      final guardsAdded = _filterUsersByDate(users, startOfDay, endOfDay);

      // Generate summary
      final summary = _generateDailySummary(reports, locationsAdded, guardsAdded);

      return DailyReport(
        id: 'daily_${date.millisecondsSinceEpoch}',
        date: date,
        patrolReports: reports,
        locationsAdded: locationsAdded,
        guardsAdded: guardsAdded,
        summary: summary,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to generate daily report: $e');
    }
  }

  /// Generate a comprehensive monthly report
  Future<MonthlyReport> generateMonthlyReport(int year, int month) async {
    try {
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

      // Generate daily reports for the month
      final dailyReports = <DailyReport>[];
      for (int day = 1; day <= endOfMonth.day; day++) {
        final date = DateTime(year, month, day);
        try {
          final dailyReport = await generateDailyReport(date);
          dailyReports.add(dailyReport);
        } catch (e) {
          // Continue even if a day fails
          print('Failed to generate report for $date: $e');
        }
      }

      // Generate monthly summary
      final monthlySummary = _generateMonthlySummary(dailyReports);

      // Generate trend analysis
      final trends = _generateTrendAnalysis(dailyReports);

      return MonthlyReport(
        id: 'monthly_${year}_${month}',
        year: year,
        month: month,
        dailyReports: dailyReports,
        monthlySummary: monthlySummary,
        trends: trends,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to generate monthly report: $e');
    }
  }

  /// Auto-generate monthly reports (should be called monthly)
  Future<void> autoGenerateMonthlyReport() async {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    
    try {
      final monthlyReport = await generateMonthlyReport(lastMonth.year, lastMonth.month);
      await saveMonthlyReport(monthlyReport);
    } catch (e) {
      throw Exception('Failed to auto-generate monthly report: $e');
    }
  }

  /// Save daily report to Firestore
  Future<void> saveDailyReport(DailyReport report) async {
    try {
      await _firestore.collection('daily_reports').doc(report.id).set(report.toMap());
    } catch (e) {
      throw Exception('Failed to save daily report: $e');
    }
  }

  /// Save monthly report to Firestore
  Future<void> saveMonthlyReport(MonthlyReport report) async {
    try {
      await _firestore.collection('monthly_reports').doc(report.id).set(report.toMap());
    } catch (e) {
      throw Exception('Failed to save monthly report: $e');
    }
  }

  /// Get daily reports for a date range
  Future<List<DailyReport>> getDailyReports(DateTime start, DateTime end) async {
    try {
      final snapshot = await _firestore
          .collection('daily_reports')
          .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('date', isLessThanOrEqualTo: end.toIso8601String())
          .orderBy('date')
          .get();
      return snapshot.docs.map((doc) => DailyReport.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get daily reports: $e');
    }
  }

  /// Get monthly reports
  Future<List<MonthlyReport>> getMonthlyReports({int? year}) async {
    try {
      CollectionReference reportsRef = _firestore.collection('monthly_reports');
      Query query = reportsRef.orderBy('year', descending: true).orderBy('month', descending: true);
      
      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => MonthlyReport.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to get monthly reports: $e');
    }
  }

  /// Export report to CSV format
  Future<String> exportDailyReportToCSV(DailyReport report) async {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Daily Report - ${report.date.toString().split(' ')[0]}');
    buffer.writeln('Generated: ${report.generatedAt.toString().split('.')[0]}');
    buffer.writeln();

    // Summary
    buffer.writeln('SUMMARY');
    buffer.writeln('Total Patrols,${report.summary.totalPatrols}');
    buffer.writeln('Unique Locations,${report.summary.uniqueLocations}');
    buffer.writeln('Active Guards,${report.summary.activeGuards}');
    buffer.writeln();

    // Status Breakdown
    buffer.writeln('STATUS BREAKDOWN');
    for (final entry in report.summary.statusBreakdown.entries) {
      buffer.writeln('${entry.key},${entry.value}');
    }
    buffer.writeln();

    // Patrol Reports
    buffer.writeln('PATROL REPORTS');
    buffer.writeln('Time,Guard,Location,Status,Notes,Latitude,Longitude');
    for (final patrolReport in report.patrolReports) {
      buffer.writeln('${patrolReport.timestamp.toString().split('.')[0]},${patrolReport.userName},${patrolReport.locationName},${patrolReport.status},${patrolReport.notes},${patrolReport.latitude},${patrolReport.longitude}');
    }
    buffer.writeln();

    // Locations Added
    buffer.writeln('LOCATIONS ADDED');
    buffer.writeln('Time,Location Name,Added By,QR Code');
    for (final location in report.locationsAdded) {
      buffer.writeln('${location.addedAt.toString().split('.')[0]},${location.locationName},${location.addedBy},${location.qrCode}');
    }
    buffer.writeln();

    // Guards Added
    buffer.writeln('GUARDS ADDED');
    buffer.writeln('Time,Guard Name,Email,Role,Added By');
    for (final guard in report.guardsAdded) {
      buffer.writeln('${guard.addedAt.toString().split('.')[0]},${guard.guardName},${guard.email},${guard.role},${guard.addedBy}');
    }

    return buffer.toString();
  }

  /// Export monthly report to CSV format
  Future<String> exportMonthlyReportToCSV(MonthlyReport report) async {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Monthly Report - ${_getMonthName(report.month)} ${report.year}');
    buffer.writeln('Generated: ${report.generatedAt.toString().split('.')[0]}');
    buffer.writeln();

    // Monthly Summary
    buffer.writeln('MONTHLY SUMMARY');
    buffer.writeln('Total Patrols,${report.monthlySummary.totalPatrols}');
    buffer.writeln('Total Locations,${report.monthlySummary.totalLocations}');
    buffer.writeln('Total Guards,${report.monthlySummary.totalGuards}');
    buffer.writeln('Average Daily Patrols,${report.monthlySummary.averageDailyPatrols.toStringAsFixed(2)}');
    buffer.writeln();

    // Daily Breakdown
    buffer.writeln('DAILY BREAKDOWN');
    buffer.writeln('Date,Total Patrols,Unique Locations,Active Guards');
    for (final dailyReport in report.dailyReports) {
      buffer.writeln('${dailyReport.date.toString().split(' ')[0]},${dailyReport.summary.totalPatrols},${dailyReport.summary.uniqueLocations},${dailyReport.summary.activeGuards}');
    }
    buffer.writeln();

    // Top Performers
    buffer.writeln('TOP PERFORMERS');
    for (final performer in report.monthlySummary.monthlyTopPerformers) {
      buffer.writeln(performer);
    }
    buffer.writeln();

    // New Locations
    buffer.writeln('NEW LOCATIONS');
    for (final location in report.monthlySummary.newLocations) {
      buffer.writeln(location);
    }
    buffer.writeln();

    // New Guards
    buffer.writeln('NEW GUARDS');
    for (final guard in report.monthlySummary.newGuards) {
      buffer.writeln(guard);
    }

    return buffer.toString();
  }

  // Private helper methods

  List<LocationActivity> _filterLocationsByDate(
      List<Location> locations, DateTime start, DateTime end) {
    // For now, return empty list as Location model doesn't have creation time
    // In a real implementation, you'd add createdAt field to Location model
    return [];
  }

  List<GuardActivity> _filterUsersByDate(
      List<User> users, DateTime start, DateTime end) {
    // For now, return empty list as User model doesn't have creation time
    // In a real implementation, you'd add createdAt field to User model
    return [];
  }

  ReportSummary _generateDailySummary(
      List<Report> reports, List<LocationActivity> locations, List<GuardActivity> guards) {
    final statusBreakdown = <String, int>{};
    final locationActivity = <String, int>{};
    final activeGuards = <String>{};
    final criticalAlerts = <String>[];

    for (final report in reports) {
      statusBreakdown[report.status] = (statusBreakdown[report.status] ?? 0) + 1;
      locationActivity[report.locationName] = (locationActivity[report.locationName] ?? 0) + 1;
      activeGuards.add(report.userId);
      
      if (report.status == 'emergency') {
        criticalAlerts.add('${report.locationName}: ${report.notes}');
      }
    }

    // Calculate top performers (guards with most patrols)
    final guardCounts = <String, int>{};
    for (final report in reports) {
      guardCounts[report.userName] = (guardCounts[report.userName] ?? 0) + 1;
    }
    
    final sortedEntries = guardCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topPerformers = sortedEntries
      .take(5)
      .map((e) => '${e.key} (${e.value} patrols)')
      .toList();

    return ReportSummary(
      totalPatrols: reports.length,
      uniqueLocations: locationActivity.length,
      activeGuards: activeGuards.length,
      statusBreakdown: statusBreakdown,
      locationActivity: locationActivity,
      topPerformers: topPerformers,
      criticalAlerts: criticalAlerts,
    );
  }

  MonthlySummary _generateMonthlySummary(List<DailyReport> dailyReports) {
    int totalPatrols = 0;
    int totalLocations = 0;
    final allGuards = <String>{};
    final monthlyStatusBreakdown = <String, int>{};
    final guardPatrolCounts = <String, int>{};
    final newLocations = <String>{};
    final newGuards = <String>{};

    for (final dailyReport in dailyReports) {
      totalPatrols += dailyReport.summary.totalPatrols;
      totalLocations += dailyReport.summary.uniqueLocations;

      // Aggregate status breakdown
      for (final entry in dailyReport.summary.statusBreakdown.entries) {
        monthlyStatusBreakdown[entry.key] = (monthlyStatusBreakdown[entry.key] ?? 0) + entry.value;
      }

      // Track guard performance
      for (final report in dailyReport.patrolReports) {
        guardPatrolCounts[report.userName] = (guardPatrolCounts[report.userName] ?? 0) + 1;
        allGuards.add(report.userName);
      }

      // Track new locations and guards
      for (final location in dailyReport.locationsAdded) {
        newLocations.add(location.locationName);
      }
      for (final guard in dailyReport.guardsAdded) {
        newGuards.add(guard.guardName);
      }
    }

    // Calculate average daily patrols
    final averageDailyPatrols = dailyReports.isNotEmpty ? totalPatrols / dailyReports.length : 0.0;

    // Calculate top performers
    final sortedEntries = guardPatrolCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topPerformers = sortedEntries
      .take(10)
      .map((e) => '${e.key} (${e.value} patrols)')
      .toList();

    // Calculate performance scores
    final guardPerformanceScores = <String, double>{};
    final maxPatrols = guardPatrolCounts.values.isNotEmpty ? guardPatrolCounts.values.reduce(max) : 1;
    
    for (final entry in guardPatrolCounts.entries) {
      guardPerformanceScores[entry.key] = (entry.value / maxPatrols) * 100;
    }

    return MonthlySummary(
      totalPatrols: totalPatrols,
      totalLocations: totalLocations,
      totalGuards: allGuards.length,
      averageDailyPatrols: averageDailyPatrols,
      monthlyStatusBreakdown: monthlyStatusBreakdown,
      monthlyTopPerformers: topPerformers,
      newLocations: newLocations.toList(),
      newGuards: newGuards.toList(),
      guardPerformanceScores: guardPerformanceScores,
    );
  }

  List<TrendAnalysis> _generateTrendAnalysis(List<DailyReport> dailyReports) {
    final trends = <TrendAnalysis>[];
    
    if (dailyReports.length < 2) return trends;

    // Patrol count trend
    final patrolCounts = dailyReports.map((r) => r.summary.totalPatrols.toDouble()).toList();
    trends.add(_calculateTrend('Daily Patrols', patrolCounts));

    // Active guards trend
    final guardCounts = dailyReports.map((r) => r.summary.activeGuards.toDouble()).toList();
    trends.add(_calculateTrend('Active Guards', guardCounts));

    // Location activity trend
    final locationCounts = dailyReports.map((r) => r.summary.uniqueLocations.toDouble()).toList();
    trends.add(_calculateTrend('Active Locations', locationCounts));

    return trends;
  }

  TrendAnalysis _calculateTrend(String metric, List<double> values) {
    if (values.length < 2) {
      return TrendAnalysis(
        metric: metric,
        dailyValues: values,
        trendPercentage: 0.0,
        trendDirection: 'stable',
      );
    }

    // Simple trend calculation: compare first half to second half
    final midPoint = values.length ~/ 2;
    final firstHalf = values.take(midPoint).toList();
    final secondHalf = values.skip(midPoint).toList();

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    final trendPercentage = firstAvg != 0 ? ((secondAvg - firstAvg) / firstAvg) * 100 : 0.0;
    
    String trendDirection;
    if (trendPercentage > 5) {
      trendDirection = 'up';
    } else if (trendPercentage < -5) {
      trendDirection = 'down';
    } else {
      trendDirection = 'stable';
    }

    return TrendAnalysis(
      metric: metric,
      dailyValues: values,
      trendPercentage: trendPercentage,
      trendDirection: trendDirection,
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
