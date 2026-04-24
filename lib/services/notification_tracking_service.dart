import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/alert.dart';
import 'alert_service.dart';

class NotificationTrackingService {
  static final NotificationTrackingService _instance = NotificationTrackingService._internal();
  factory NotificationTrackingService() => _instance;
  NotificationTrackingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Stream controllers for real-time updates
  final _unreadCountController = StreamController<int>.broadcast();
  final _notificationListController = StreamController<List<UnreadNotification>>.broadcast();
  
  Stream<int> get unreadCountStream => _unreadCountController.stream;
  Stream<List<UnreadNotification>> get notificationListStream => _notificationListController.stream;
  
  int _currentUnreadCount = 0;
  List<UnreadNotification> _currentNotifications = [];
  String? _currentUserId;

  /// Initialize notification tracking for a user
  void initializeForUser(String userId) {
    _currentUserId = userId;
    _startRealtimeTracking();
    debugPrint('Notification tracking initialized for user: $userId');
  }

  /// Start real-time tracking of unread notifications
  void _startRealtimeTracking() {
    if (_currentUserId == null) return;

    // Listen to active alerts that target this user
    _firestore
        .collection('alerts')
        .where('targetUsers', arrayContains: _currentUserId)
        .where('status', whereIn: ['active', 'acknowledged'])
        .snapshots()
        .listen((snapshot) {
      _processAlertSnapshot(snapshot);
    });

    // Listen to mass notifications
    _firestore
        .collection('mass_notifications')
        .where('targetUsers', arrayContains: _currentUserId)
        .where('sentAt', isGreaterThan: '')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _processMassNotificationSnapshot(snapshot);
    });
  }

  /// Process alert snapshot and update unread count
  void _processAlertSnapshot(QuerySnapshot snapshot) {
    final newNotifications = <UnreadNotification>[];
    
    for (final doc in snapshot.docs) {
      final alert = Alert.fromMap(doc.data() as Map<String, dynamic>);
      
      // Check if this alert is unread for current user
      if (_isAlertUnread(alert)) {
        final notification = UnreadNotification(
          id: alert.id,
          type: NotificationType.alert,
          title: alert.title,
          message: alert.message,
          priority: alert.priority,
          createdAt: alert.createdAt,
          alertId: alert.id,
        );
        newNotifications.add(notification);
      }
    }
    
    _updateNotifications(newNotifications);
  }

  /// Process mass notification snapshot and update unread count
  void _processMassNotificationSnapshot(QuerySnapshot snapshot) {
    final newNotifications = <UnreadNotification>[];
    
    for (final doc in snapshot.docs) {
      final notification = MassNotification.fromMap(doc.data() as Map<String, dynamic>);
      
      // Check if this notification is unread for current user
      if (_isMassNotificationUnread(notification)) {
        final unreadNotification = UnreadNotification(
          id: notification.id,
          type: NotificationType.massNotification,
          title: notification.title,
          message: notification.message,
          priority: notification.priority,
          createdAt: notification.sentAt ?? notification.createdAt,
          massNotificationId: notification.id,
        );
        newNotifications.add(unreadNotification);
      }
    }
    
    _updateNotifications(newNotifications);
  }

  /// Check if an alert is unread for the current user
  bool _isAlertUnread(Alert alert) {
    if (_currentUserId == null) return false;
    
    // Check if user has already read this alert
    return !alert.targetUsers.contains(_currentUserId) || 
           !_hasUserAcknowledgedAlert(alert.id);
  }

  /// Check if a mass notification is unread for the current user
  bool _isMassNotificationUnread(MassNotification notification) {
    if (_currentUserId == null) return false;
    
    // Check delivery status for this user
    final userStatus = notification.deliveryStatus[_currentUserId];
    return userStatus == null || userStatus['read'] != true;
  }

  /// Check if user has acknowledged an alert
  bool _hasUserAcknowledgedAlert(String alertId) {
    // This would check a separate collection that tracks user acknowledgments
    // For now, we'll assume alerts are unread until explicitly marked as read
    return false;
  }

  /// Update the notifications list and count
  void _updateNotifications(List<UnreadNotification> newNotifications) {
    // Sort by priority and creation time
    newNotifications.sort((a, b) {
      // First sort by priority (critical first)
      final priorityOrder = {
        AlertPriority.critical: 0,
        AlertPriority.high: 1,
        AlertPriority.medium: 2,
        AlertPriority.low: 3,
      };
      
      final priorityComparison = priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
      if (priorityComparison != 0) return priorityComparison;
      
      // Then sort by creation time (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });

    _currentNotifications = newNotifications;
    _currentUnreadCount = newNotifications.length;
    
    // Update streams
    _unreadCountController.add(_currentUnreadCount);
    _notificationListController.add(_currentNotifications);
    
    debugPrint('Unread notification count updated: $_currentUnreadCount');
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId, {NotificationType? type}) async {
    if (_currentUserId == null) return;
    
    try {
      if (type == NotificationType.alert) {
        // Mark alert as acknowledged by user
        await _firestore.collection('user_alert_read_status').doc('${_currentUserId}_${notificationId}').set({
          'userId': _currentUserId,
          'alertId': notificationId,
          'readAt': DateTime.now().toIso8601String(),
          'read': true,
        });
      } else if (type == NotificationType.massNotification) {
        // Update mass notification delivery status
        await _firestore.collection('mass_notifications').doc(notificationId).update({
          'deliveryStatus.${_currentUserId}.read': true,
          'deliveryStatus.${_currentUserId}.readAt': DateTime.now().toIso8601String(),
        });
      }
      
      debugPrint('Notification marked as read: $notificationId');
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;
    
    try {
      final batch = _firestore.batch();
      
      // Mark all alerts as read
      for (final notification in _currentNotifications) {
        if (notification.type == NotificationType.alert) {
          final docRef = _firestore.collection('user_alert_read_status').doc('${_currentUserId}_${notification.alertId}');
          batch.set(docRef, {
            'userId': _currentUserId,
            'alertId': notification.alertId,
            'readAt': DateTime.now().toIso8601String(),
            'read': true,
          });
        } else if (notification.type == NotificationType.massNotification) {
          final docRef = _firestore.collection('mass_notifications').doc(notification.massNotificationId);
          batch.update(docRef, {
            'deliveryStatus.${_currentUserId}.read': true,
            'deliveryStatus.${_currentUserId}.readAt': DateTime.now().toIso8601String(),
          });
        }
      }
      
      await batch.commit();
      debugPrint('All notifications marked as read');
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
    }
  }

  /// Get current unread count
  int get currentUnreadCount => _currentUnreadCount;

  /// Get current notifications
  List<UnreadNotification> get currentNotifications => _currentNotifications;

  /// Dispose of stream controllers
  void dispose() {
    _unreadCountController.close();
    _notificationListController.close();
  }
}

class UnreadNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final AlertPriority priority;
  final DateTime createdAt;
  final String? alertId;
  final String? massNotificationId;

  UnreadNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.priority,
    required this.createdAt,
    this.alertId,
    this.massNotificationId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'alertId': alertId,
      'massNotificationId': massNotificationId,
    };
  }

  factory UnreadNotification.fromMap(Map<String, dynamic> map) {
    return UnreadNotification(
      id: map['id'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.alert,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      priority: AlertPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => AlertPriority.medium,
      ),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      alertId: map['alertId'],
      massNotificationId: map['massNotificationId'],
    );
  }
}

enum NotificationType {
  alert,
  massNotification,
}
