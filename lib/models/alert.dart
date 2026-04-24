enum AlertType {
  emergency,
  warning,
  info,
  maintenance,
  security,
  weather,
  system,
  custom,
}

enum AlertPriority {
  low,
  medium,
  high,
  critical,
}

enum AlertStatus {
  active,
  resolved,
  acknowledged,
  dismissed,
}

enum NotificationType {
  push,
  email,
  sms,
  inApp,
  all,
}

class Alert {
  final String id;
  final String title;
  final String message;
  final AlertType type;
  final AlertPriority priority;
  final AlertStatus status;
  final String? locationId;
  final String? locationName;
  final String? guardId;
  final String? guardName;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final DateTime? acknowledgedAt;
  final String? resolvedBy;
  final String? acknowledgedBy;
  final List<String> attachments;
  final Map<String, dynamic> metadata;
  final bool isMassAlert;
  final List<String> targetUsers;

  Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.status,
    this.locationId,
    this.locationName,
    this.guardId,
    this.guardName,
    required this.createdAt,
    this.resolvedAt,
    this.acknowledgedAt,
    this.resolvedBy,
    this.acknowledgedBy,
    this.attachments = const [],
    this.metadata = const {},
    this.isMassAlert = false,
    this.targetUsers = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'status': status.name,
      'locationId': locationId,
      'locationName': locationName,
      'guardId': guardId,
      'guardName': guardName,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'resolvedBy': resolvedBy,
      'acknowledgedBy': acknowledgedBy,
      'attachments': attachments,
      'metadata': metadata,
      'isMassAlert': isMassAlert,
      'targetUsers': targetUsers,
    };
  }

  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: AlertType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AlertType.info,
      ),
      priority: AlertPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => AlertPriority.medium,
      ),
      status: AlertStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AlertStatus.active,
      ),
      locationId: map['locationId'],
      locationName: map['locationName'],
      guardId: map['guardId'],
      guardName: map['guardName'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      resolvedAt: map['resolvedAt'] != null ? DateTime.parse(map['resolvedAt']) : null,
      acknowledgedAt: map['acknowledgedAt'] != null ? DateTime.parse(map['acknowledgedAt']) : null,
      resolvedBy: map['resolvedBy'],
      acknowledgedBy: map['acknowledgedBy'],
      attachments: List<String>.from(map['attachments'] ?? []),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      isMassAlert: map['isMassAlert'] ?? false,
      targetUsers: List<String>.from(map['targetUsers'] ?? []),
    );
  }

  Alert copyWith({
    String? id,
    String? title,
    String? message,
    AlertType? type,
    AlertPriority? priority,
    AlertStatus? status,
    String? locationId,
    String? locationName,
    String? guardId,
    String? guardName,
    DateTime? createdAt,
    DateTime? resolvedAt,
    DateTime? acknowledgedAt,
    String? resolvedBy,
    String? acknowledgedBy,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    bool? isMassAlert,
    List<String>? targetUsers,
  }) {
    return Alert(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      guardId: guardId ?? this.guardId,
      guardName: guardName ?? this.guardName,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
      isMassAlert: isMassAlert ?? this.isMassAlert,
      targetUsers: targetUsers ?? this.targetUsers,
    );
  }
}

class MassNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType notificationType;
  final AlertPriority priority;
  final List<String> targetGroups; // 'all_guards', 'all_managers', 'location_specific', etc.
  final List<String> targetUsers;
  final String? locationId; // For location-specific notifications
  final DateTime scheduledFor;
  final DateTime createdAt;
  final DateTime? sentAt;
  final bool isRecurring;
  final String? recurrencePattern; // 'daily', 'weekly', 'monthly'
  final Map<String, dynamic> deliveryStatus; // Track delivery per user
  final String? createdBy;

  MassNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.priority,
    required this.targetGroups,
    required this.targetUsers,
    this.locationId,
    required this.scheduledFor,
    required this.createdAt,
    this.sentAt,
    this.isRecurring = false,
    this.recurrencePattern,
    this.deliveryStatus = const {},
    this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'notificationType': notificationType.name,
      'priority': priority.name,
      'targetGroups': targetGroups,
      'targetUsers': targetUsers,
      'locationId': locationId,
      'scheduledFor': scheduledFor.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern,
      'deliveryStatus': deliveryStatus,
      'createdBy': createdBy,
    };
  }

  factory MassNotification.fromMap(Map<String, dynamic> map) {
    return MassNotification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      notificationType: NotificationType.values.firstWhere(
        (e) => e.name == map['notificationType'],
        orElse: () => NotificationType.inApp,
      ),
      priority: AlertPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => AlertPriority.medium,
      ),
      targetGroups: List<String>.from(map['targetGroups'] ?? []),
      targetUsers: List<String>.from(map['targetUsers'] ?? []),
      locationId: map['locationId'],
      scheduledFor: DateTime.parse(map['scheduledFor'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      sentAt: map['sentAt'] != null ? DateTime.parse(map['sentAt']) : null,
      isRecurring: map['isRecurring'] ?? false,
      recurrencePattern: map['recurrencePattern'],
      deliveryStatus: Map<String, dynamic>.from(map['deliveryStatus'] ?? {}),
      createdBy: map['createdBy'],
    );
  }
}

class AlertTemplate {
  final String id;
  final String name;
  final String title;
  final String message;
  final AlertType type;
  final AlertPriority priority;
  final List<String> targetGroups;
  final bool isQuickAction;
  final Map<String, dynamic> variables; // Template variables like {location}, {guard}, etc.

  AlertTemplate({
    required this.id,
    required this.name,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.targetGroups,
    this.isQuickAction = false,
    this.variables = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'targetGroups': targetGroups,
      'isQuickAction': isQuickAction,
      'variables': variables,
    };
  }

  factory AlertTemplate.fromMap(Map<String, dynamic> map) {
    return AlertTemplate(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: AlertType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AlertType.info,
      ),
      priority: AlertPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => AlertPriority.medium,
      ),
      targetGroups: List<String>.from(map['targetGroups'] ?? []),
      isQuickAction: map['isQuickAction'] ?? false,
      variables: Map<String, dynamic>.from(map['variables'] ?? {}),
    );
  }
}

class AlertStatistics {
  final int totalAlerts;
  final int activeAlerts;
  final int criticalAlerts;
  final int resolvedToday;
  final int acknowledgedToday;
  final Map<AlertType, int> alertsByType;
  final Map<AlertPriority, int> alertsByPriority;
  final List<Alert> recentAlerts;
  final double averageResolutionTime; // in hours

  AlertStatistics({
    required this.totalAlerts,
    required this.activeAlerts,
    required this.criticalAlerts,
    required this.resolvedToday,
    required this.acknowledgedToday,
    required this.alertsByType,
    required this.alertsByPriority,
    required this.recentAlerts,
    required this.averageResolutionTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalAlerts': totalAlerts,
      'activeAlerts': activeAlerts,
      'criticalAlerts': criticalAlerts,
      'resolvedToday': resolvedToday,
      'acknowledgedToday': acknowledgedToday,
      'alertsByType': alertsByType.map((k, v) => MapEntry(k.name, v)),
      'alertsByPriority': alertsByPriority.map((k, v) => MapEntry(k.name, v)),
      'recentAlerts': recentAlerts.map((a) => a.toMap()).toList(),
      'averageResolutionTime': averageResolutionTime,
    };
  }

  factory AlertStatistics.fromMap(Map<String, dynamic> map) {
    return AlertStatistics(
      totalAlerts: map['totalAlerts'] ?? 0,
      activeAlerts: map['activeAlerts'] ?? 0,
      criticalAlerts: map['criticalAlerts'] ?? 0,
      resolvedToday: map['resolvedToday'] ?? 0,
      acknowledgedToday: map['acknowledgedToday'] ?? 0,
      alertsByType: Map<AlertType, int>.from(
        (map['alertsByType'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(AlertType.values.firstWhere((e) => e.name == k), v as int),
        ),
      ),
      alertsByPriority: Map<AlertPriority, int>.from(
        (map['alertsByPriority'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(AlertPriority.values.firstWhere((e) => e.name == k), v as int),
        ),
      ),
      recentAlerts: (map['recentAlerts'] as List<dynamic>?)
          ?.map((a) => Alert.fromMap(a))
          .toList() ?? [],
      averageResolutionTime: (map['averageResolutionTime'] ?? 0.0).toDouble(),
    );
  }
}
