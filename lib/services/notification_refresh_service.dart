import 'package:flutter/foundation.dart';

/// Service to manage notification badge refresh across the app
class NotificationRefreshService {
  static final NotificationRefreshService _instance = NotificationRefreshService._internal();
  factory NotificationRefreshService() => _instance;
  NotificationRefreshService._internal();

  final List<VoidCallback> _listeners = [];

  /// Add a listener to be called when notifications need refreshing
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners to refresh their notification badges
  void refreshAllNotifications() {
    for (final listener in _listeners) {
      try {
        listener();
      } catch (e) {
        debugPrint('Error refreshing notification: $e');
      }
    }
  }

  /// Clear all listeners
  void clearListeners() {
    _listeners.clear();
  }
}
