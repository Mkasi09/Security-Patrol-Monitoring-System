import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/alert.dart';
import '../models/user.dart';
import '../models/location.dart';
import 'firestore_service.dart';
import 'id_generator_service.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new alert
  Future<String> createAlert({
    required String title,
    required String message,
    required AlertType type,
    required AlertPriority priority,
    String? locationId,
    String? locationName,
    String? guardId,
    String? guardName,
    List<String> targetUsers = const [],
    bool isMassAlert = false,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final alertId = 'alert_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
      
      final alert = Alert(
        id: alertId,
        title: title,
        message: message,
        type: type,
        priority: priority,
        status: AlertStatus.active,
        locationId: locationId,
        locationName: locationName,
        guardId: guardId,
        guardName: guardName,
        createdAt: DateTime.now(),
        targetUsers: targetUsers,
        isMassAlert: isMassAlert,
        metadata: metadata,
      );

      await _firestore.collection('alerts').doc(alertId).set(alert.toMap());
      
      // Send notifications if it's a mass alert or has target users
      if (isMassAlert || targetUsers.isNotEmpty) {
        await _sendAlertNotifications(alert);
      }

      debugPrint('Alert created: $alertId');
      return alertId;
    } catch (e) {
      throw Exception('Failed to create alert: $e');
    }
  }

  /// Get all alerts with optional filtering
  Future<List<Alert>> getAlerts({
    AlertStatus? status,
    AlertType? type,
    AlertPriority? priority,
    String? locationId,
    String? guardId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection('alerts').orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      if (priority != null) {
        query = query.where('priority', isEqualTo: priority.name);
      }
      if (locationId != null) {
        query = query.where('locationId', isEqualTo: locationId);
      }
      if (guardId != null) {
        query = query.where('guardId', isEqualTo: guardId);
      }
      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs.map((doc) => Alert.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to get alerts: $e');
    }
  }

  /// Get alert by ID
  Future<Alert?> getAlertById(String alertId) async {
    try {
      final doc = await _firestore.collection('alerts').doc(alertId).get();
      if (doc.exists) {
        return Alert.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get alert: $e');
    }
  }

  /// Update alert status
  Future<void> updateAlertStatus(String alertId, AlertStatus status, {String? updatedBy}) async {
    try {
      final updateData = {
        'status': status.name,
      };

      if (status == AlertStatus.resolved) {
        updateData['resolvedAt'] = DateTime.now().toIso8601String();
        if (updatedBy != null) updateData['resolvedBy'] = updatedBy;
      } else if (status == AlertStatus.acknowledged) {
        updateData['acknowledgedAt'] = DateTime.now().toIso8601String();
        if (updatedBy != null) updateData['acknowledgedBy'] = updatedBy;
      }

      await _firestore.collection('alerts').doc(alertId).update(updateData);
      debugPrint('Alert $alertId status updated to: ${status.name}');
    } catch (e) {
      throw Exception('Failed to update alert status: $e');
    }
  }

  /// Delete an alert
  Future<void> deleteAlert(String alertId) async {
    try {
      await _firestore.collection('alerts').doc(alertId).delete();
      debugPrint('Alert $alertId deleted');
    } catch (e) {
      throw Exception('Failed to delete alert: $e');
    }
  }

  /// Get alert statistics
  Future<AlertStatistics> getAlertStatistics() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Get all alerts for statistics
      final allAlerts = await getAlerts(limit: 1000);
      
      // Calculate statistics
      final activeAlerts = allAlerts.where((a) => a.status == AlertStatus.active).length;
      final criticalAlerts = allAlerts.where((a) => a.priority == AlertPriority.critical && a.status == AlertStatus.active).length;
      
      final resolvedToday = allAlerts.where((a) => 
        a.status == AlertStatus.resolved &&
        a.resolvedAt != null &&
        a.resolvedAt!.isAfter(startOfDay)
      ).length;
      
      final acknowledgedToday = allAlerts.where((a) =>
        a.status == AlertStatus.acknowledged &&
        a.acknowledgedAt != null &&
        a.acknowledgedAt!.isAfter(startOfDay)
      ).length;

      // Group by type and priority
      final alertsByType = <AlertType, int>{};
      final alertsByPriority = <AlertPriority, int>{};
      
      for (final alert in allAlerts) {
        alertsByType[alert.type] = (alertsByType[alert.type] ?? 0) + 1;
        alertsByPriority[alert.priority] = (alertsByPriority[alert.priority] ?? 0) + 1;
      }

      // Calculate average resolution time
      final resolvedAlerts = allAlerts.where((a) => a.resolvedAt != null).toList();
      double averageResolutionTime = 0.0;
      
      if (resolvedAlerts.isNotEmpty) {
        final totalResolutionTime = resolvedAlerts.fold<double>(0.0, (sum, alert) {
          return sum + alert.resolvedAt!.difference(alert.createdAt).inHours;
        });
        averageResolutionTime = totalResolutionTime / resolvedAlerts.length;
      }

      // Get recent alerts (last 24 hours)
      final recentAlerts = allAlerts.where((a) => 
        a.createdAt.isAfter(now.subtract(const Duration(hours: 24)))
      ).take(10).toList();

      return AlertStatistics(
        totalAlerts: allAlerts.length,
        activeAlerts: activeAlerts,
        criticalAlerts: criticalAlerts,
        resolvedToday: resolvedToday,
        acknowledgedToday: acknowledgedToday,
        alertsByType: alertsByType,
        alertsByPriority: alertsByPriority,
        recentAlerts: recentAlerts,
        averageResolutionTime: averageResolutionTime,
      );
    } catch (e) {
      throw Exception('Failed to get alert statistics: $e');
    }
  }

  /// Create a mass notification
  Future<String> createMassNotification({
    required String title,
    required String message,
    required NotificationType notificationType,
    required AlertPriority priority,
    required List<String> targetGroups,
    List<String> targetUsers = const [],
    String? locationId,
    DateTime? scheduledFor,
    bool isRecurring = false,
    String? recurrencePattern,
    String? createdBy,
  }) async {
    try {
      final notificationId = 'notif_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
      
      final notification = MassNotification(
        id: notificationId,
        title: title,
        message: message,
        notificationType: notificationType,
        priority: priority,
        targetGroups: targetGroups,
        targetUsers: targetUsers,
        locationId: locationId,
        scheduledFor: scheduledFor ?? DateTime.now(),
        createdAt: DateTime.now(),
        isRecurring: isRecurring,
        recurrencePattern: recurrencePattern,
        createdBy: createdBy,
      );

      await _firestore.collection('mass_notifications').doc(notificationId).set(notification.toMap());
      
      // If scheduled for now, send immediately
      if ((scheduledFor ?? DateTime.now()).isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
        await _sendMassNotification(notification);
      }

      debugPrint('Mass notification created: $notificationId');
      return notificationId;
    } catch (e) {
      throw Exception('Failed to create mass notification: $e');
    }
  }

  /// Get mass notifications
  Future<List<MassNotification>> getMassNotifications({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('mass_notifications')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) => MassNotification.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get mass notifications: $e');
    }
  }

  /// Get alert templates
  Future<List<AlertTemplate>> getAlertTemplates() async {
    try {
      final snapshot = await _firestore.collection('alert_templates').get();
      return snapshot.docs.map((doc) => AlertTemplate.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get alert templates: $e');
    }
  }

  /// Create alert from template
  Future<String> createAlertFromTemplate({
    required String templateId,
    Map<String, dynamic> variables = const {},
    String? locationId,
    String? locationName,
    String? guardId,
    String? guardName,
  }) async {
    try {
      final templateDoc = await _firestore.collection('alert_templates').doc(templateId).get();
      if (!templateDoc.exists) {
        throw Exception('Alert template not found');
      }

      final template = AlertTemplate.fromMap(templateDoc.data() as Map<String, dynamic>);
      
      // Replace template variables
      String title = _replaceVariables(template.title, variables);
      String message = _replaceVariables(template.message, variables);

      return await createAlert(
        title: title,
        message: message,
        type: template.type,
        priority: template.priority,
        locationId: locationId,
        locationName: locationName,
        guardId: guardId,
        guardName: guardName,
        targetUsers: template.targetGroups,
      );
    } catch (e) {
      throw Exception('Failed to create alert from template: $e');
    }
  }

  /// Get active alerts for a specific user
  Future<List<Alert>> getAlertsForUser(String userId, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('alerts')
          .where('targetUsers', arrayContains: userId)
          .where('status', whereIn: ['active', 'acknowledged'])
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) => Alert.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get alerts for user: $e');
    }
  }

  /// Send notifications for an alert
  Future<void> _sendAlertNotifications(Alert alert) async {
    try {
      // This would integrate with your notification service
      // For now, we'll just log the action
      debugPrint('Sending notifications for alert: ${alert.id}');
      debugPrint('Target users: ${alert.targetUsers}');
      
      // In a real implementation, you would:
      // 1. Send push notifications via Firebase Cloud Messaging
      // 2. Send emails via email service
      // 3. Send SMS via SMS service
      // 4. Create in-app notifications
      
    } catch (e) {
      debugPrint('Failed to send alert notifications: $e');
    }
  }

  /// Send mass notification
  Future<void> _sendMassNotification(MassNotification notification) async {
    try {
      // This would integrate with your notification service
      debugPrint('Sending mass notification: ${notification.id}');
      debugPrint('Target groups: ${notification.targetGroups}');
      debugPrint('Target users: ${notification.targetUsers}');
      
      // Update delivery status
      await _firestore.collection('mass_notifications').doc(notification.id).update({
        'sentAt': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      debugPrint('Failed to send mass notification: $e');
    }
  }

  /// Replace template variables
  String _replaceVariables(String text, Map<String, dynamic> variables) {
    String result = text;
    variables.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });
    return result;
  }

  /// Initialize default alert templates
  Future<void> initializeDefaultTemplates() async {
    try {
      final templates = [
        AlertTemplate(
          id: 'emergency_template',
          name: 'Emergency Alert',
          title: 'EMERGENCY: {location}',
          message: 'Emergency situation detected at {location}. {guard} please respond immediately. Details: {details}',
          type: AlertType.emergency,
          priority: AlertPriority.critical,
          targetGroups: ['all_guards', 'all_managers'],
          isQuickAction: true,
          variables: {'location': '', 'guard': '', 'details': ''},
        ),
        AlertTemplate(
          id: 'maintenance_template',
          name: 'Maintenance Required',
          title: 'Maintenance Required: {location}',
          message: 'Maintenance attention needed at {location}. Issue: {issue}. Reported by: {guard}',
          type: AlertType.maintenance,
          priority: AlertPriority.medium,
          targetGroups: ['all_managers'],
          isQuickAction: true,
          variables: {'location': '', 'issue': '', 'guard': ''},
        ),
        AlertTemplate(
          id: 'security_template',
          name: 'Security Alert',
          title: 'Security Alert: {location}',
          message: 'Security concern at {location}. {guard} please investigate. Details: {details}',
          type: AlertType.security,
          priority: AlertPriority.high,
          targetGroups: ['all_guards', 'all_managers'],
          isQuickAction: true,
          variables: {'location': '', 'guard': '', 'details': ''},
        ),
      ];

      for (final template in templates) {
        await _firestore.collection('alert_templates').doc(template.id).set(template.toMap());
      }
      
      debugPrint('Default alert templates initialized');
    } catch (e) {
      debugPrint('Failed to initialize default templates: $e');
    }
  }

  /// Schedule periodic alert cleanup
  void startAlertCleanupScheduler() {
    // Clean up resolved alerts older than 30 days
    Timer.periodic(const Duration(hours: 24), (timer) async {
      try {
        final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
        final oldAlerts = await getAlerts(endDate: cutoffDate);
        
        for (final alert in oldAlerts) {
          if (alert.status == AlertStatus.resolved) {
            await deleteAlert(alert.id);
          }
        }
        
        debugPrint('Cleaned up ${oldAlerts.length} old resolved alerts');
      } catch (e) {
        debugPrint('Failed to cleanup old alerts: $e');
      }
    });
  }
}
