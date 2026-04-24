import 'report.dart';

class DailyReport {
  final String id;
  final DateTime date;
  final List<Report> patrolReports;
  final List<LocationActivity> locationsAdded;
  final List<GuardActivity> guardsAdded;
  final ReportSummary summary;
  final DateTime generatedAt;

  DailyReport({
    required this.id,
    required this.date,
    required this.patrolReports,
    required this.locationsAdded,
    required this.guardsAdded,
    required this.summary,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'patrolReports': patrolReports.map((r) => r.toMap()).toList(),
      'locationsAdded': locationsAdded.map((l) => l.toMap()).toList(),
      'guardsAdded': guardsAdded.map((g) => g.toMap()).toList(),
      'summary': summary.toMap(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory DailyReport.fromMap(Map<String, dynamic> map) {
    return DailyReport(
      id: map['id'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      patrolReports: (map['patrolReports'] as List<dynamic>?)
          ?.map((r) => Report.fromMap(r))
          .toList() ?? [],
      locationsAdded: (map['locationsAdded'] as List<dynamic>?)
          ?.map((l) => LocationActivity.fromMap(l))
          .toList() ?? [],
      guardsAdded: (map['guardsAdded'] as List<dynamic>?)
          ?.map((g) => GuardActivity.fromMap(g))
          .toList() ?? [],
      summary: ReportSummary.fromMap(map['summary'] ?? {}),
      generatedAt: DateTime.parse(map['generatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class MonthlyReport {
  final String id;
  final int year;
  final int month;
  final List<DailyReport> dailyReports;
  final MonthlySummary monthlySummary;
  final List<TrendAnalysis> trends;
  final DateTime generatedAt;

  MonthlyReport({
    required this.id,
    required this.year,
    required this.month,
    required this.dailyReports,
    required this.monthlySummary,
    required this.trends,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'month': month,
      'dailyReports': dailyReports.map((r) => r.toMap()).toList(),
      'monthlySummary': monthlySummary.toMap(),
      'trends': trends.map((t) => t.toMap()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory MonthlyReport.fromMap(Map<String, dynamic> map) {
    return MonthlyReport(
      id: map['id'] ?? '',
      year: map['year'] ?? DateTime.now().year,
      month: map['month'] ?? DateTime.now().month,
      dailyReports: (map['dailyReports'] as List<dynamic>?)
          ?.map((r) => DailyReport.fromMap(r))
          .toList() ?? [],
      monthlySummary: MonthlySummary.fromMap(map['monthlySummary'] ?? {}),
      trends: (map['trends'] as List<dynamic>?)
          ?.map((t) => TrendAnalysis.fromMap(t))
          .toList() ?? [],
      generatedAt: DateTime.parse(map['generatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class LocationActivity {
  final String locationId;
  final String locationName;
  final String addedBy;
  final DateTime addedAt;
  final String qrCode;

  LocationActivity({
    required this.locationId,
    required this.locationName,
    required this.addedBy,
    required this.addedAt,
    required this.qrCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'locationId': locationId,
      'locationName': locationName,
      'addedBy': addedBy,
      'addedAt': addedAt.toIso8601String(),
      'qrCode': qrCode,
    };
  }

  factory LocationActivity.fromMap(Map<String, dynamic> map) {
    return LocationActivity(
      locationId: map['locationId'] ?? '',
      locationName: map['locationName'] ?? '',
      addedBy: map['addedBy'] ?? '',
      addedAt: DateTime.parse(map['addedAt'] ?? DateTime.now().toIso8601String()),
      qrCode: map['qrCode'] ?? '',
    );
  }
}

class GuardActivity {
  final String guardId;
  final String guardName;
  final String email;
  final String role;
  final String addedBy;
  final DateTime addedAt;

  GuardActivity({
    required this.guardId,
    required this.guardName,
    required this.email,
    required this.role,
    required this.addedBy,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'guardId': guardId,
      'guardName': guardName,
      'email': email,
      'role': role,
      'addedBy': addedBy,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory GuardActivity.fromMap(Map<String, dynamic> map) {
    return GuardActivity(
      guardId: map['guardId'] ?? '',
      guardName: map['guardName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      addedBy: map['addedBy'] ?? '',
      addedAt: DateTime.parse(map['addedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ReportSummary {
  final int totalPatrols;
  final int uniqueLocations;
  final int activeGuards;
  final Map<String, int> statusBreakdown;
  final Map<String, int> locationActivity;
  final List<String> topPerformers;
  final List<String> criticalAlerts;

  ReportSummary({
    required this.totalPatrols,
    required this.uniqueLocations,
    required this.activeGuards,
    required this.statusBreakdown,
    required this.locationActivity,
    required this.topPerformers,
    required this.criticalAlerts,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalPatrols': totalPatrols,
      'uniqueLocations': uniqueLocations,
      'activeGuards': activeGuards,
      'statusBreakdown': statusBreakdown,
      'locationActivity': locationActivity,
      'topPerformers': topPerformers,
      'criticalAlerts': criticalAlerts,
    };
  }

  factory ReportSummary.fromMap(Map<String, dynamic> map) {
    return ReportSummary(
      totalPatrols: map['totalPatrols'] ?? 0,
      uniqueLocations: map['uniqueLocations'] ?? 0,
      activeGuards: map['activeGuards'] ?? 0,
      statusBreakdown: Map<String, int>.from(map['statusBreakdown'] ?? {}),
      locationActivity: Map<String, int>.from(map['locationActivity'] ?? {}),
      topPerformers: List<String>.from(map['topPerformers'] ?? []),
      criticalAlerts: List<String>.from(map['criticalAlerts'] ?? []),
    );
  }
}

class MonthlySummary {
  final int totalPatrols;
  final int totalLocations;
  final int totalGuards;
  final double averageDailyPatrols;
  final Map<String, int> monthlyStatusBreakdown;
  final List<String> monthlyTopPerformers;
  final List<String> newLocations;
  final List<String> newGuards;
  final Map<String, double> guardPerformanceScores;

  MonthlySummary({
    required this.totalPatrols,
    required this.totalLocations,
    required this.totalGuards,
    required this.averageDailyPatrols,
    required this.monthlyStatusBreakdown,
    required this.monthlyTopPerformers,
    required this.newLocations,
    required this.newGuards,
    required this.guardPerformanceScores,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalPatrols': totalPatrols,
      'totalLocations': totalLocations,
      'totalGuards': totalGuards,
      'averageDailyPatrols': averageDailyPatrols,
      'monthlyStatusBreakdown': monthlyStatusBreakdown,
      'monthlyTopPerformers': monthlyTopPerformers,
      'newLocations': newLocations,
      'newGuards': newGuards,
      'guardPerformanceScores': guardPerformanceScores,
    };
  }

  factory MonthlySummary.fromMap(Map<String, dynamic> map) {
    return MonthlySummary(
      totalPatrols: map['totalPatrols'] ?? 0,
      totalLocations: map['totalLocations'] ?? 0,
      totalGuards: map['totalGuards'] ?? 0,
      averageDailyPatrols: (map['averageDailyPatrols'] ?? 0.0).toDouble(),
      monthlyStatusBreakdown: Map<String, int>.from(map['monthlyStatusBreakdown'] ?? {}),
      monthlyTopPerformers: List<String>.from(map['monthlyTopPerformers'] ?? []),
      newLocations: List<String>.from(map['newLocations'] ?? []),
      newGuards: List<String>.from(map['newGuards'] ?? []),
      guardPerformanceScores: Map<String, double>.from(map['guardPerformanceScores'] ?? {}),
    );
  }
}

class TrendAnalysis {
  final String metric;
  final List<double> dailyValues;
  final double trendPercentage;
  final String trendDirection; // 'up', 'down', 'stable'

  TrendAnalysis({
    required this.metric,
    required this.dailyValues,
    required this.trendPercentage,
    required this.trendDirection,
  });

  Map<String, dynamic> toMap() {
    return {
      'metric': metric,
      'dailyValues': dailyValues,
      'trendPercentage': trendPercentage,
      'trendDirection': trendDirection,
    };
  }

  factory TrendAnalysis.fromMap(Map<String, dynamic> map) {
    return TrendAnalysis(
      metric: map['metric'] ?? '',
      dailyValues: List<double>.from(map['dailyValues'] ?? []),
      trendPercentage: (map['trendPercentage'] ?? 0.0).toDouble(),
      trendDirection: map['trendDirection'] ?? 'stable',
    );
  }
}
