import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';
import 'firestore_service.dart';

class EmailService {
  final FirestoreService _firestoreService = FirestoreService();

  /// Check if there are any managers in the system
  Future<bool> hasManagers() async {
    try {
      final users = await _firestoreService.getAllUsers();
      final managers = users.where((user) => user.role == 'manager').toList();
      return managers.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Failed to check for managers: $e');
      return false;
    }
  }

  /// Get manager count for debugging
  Future<int> getManagerCount() async {
    try {
      final users = await _firestoreService.getAllUsers();
      final managers = users.where((user) => user.role == 'manager').toList();
      return managers.length;
    } catch (e) {
      debugPrint('❌ Failed to get manager count: $e');
      return 0;
    }
  }

  /// Send email notification to manager when a report is submitted
  /// Note: Real email sending is now handled by Cloud Function (sendReportEmail)
  /// This method provides logging and verification
  Future<void> sendReportNotificationToManager(Report report) async {
    try {
      debugPrint('🚨 SECURITY ALERT: Report submitted - triggering Cloud Function email');
      debugPrint('📍 Location: ${report.locationName}');
      debugPrint('📊 Status: ${report.status.toUpperCase()}');
      debugPrint('👤 Submitted by: ${report.userName}');
      debugPrint('🆔 Report ID: ${report.id}');
      debugPrint('⏰ Time: ${report.timestamp}');
      
      // Check if there are managers in the system
      final managerCount = await getManagerCount();
      debugPrint('👥 Found $managerCount managers in system');
      
      if (managerCount == 0) {
        debugPrint('⚠️ WARNING: No managers found - no emails will be sent');
        debugPrint('💡 Please add at least one user with role="manager"');
        return;
      }
      
      // The Cloud Function will automatically trigger when the report is saved to Firestore
      // No manual email sending needed here - just logging for verification
      debugPrint('✅ Cloud Function will now send real emails to all managers');
      debugPrint('📧 Emails will be sent via SendGrid to manager addresses');
      
      // Optional: Log notification attempt for debugging
      await _logNotificationAttempt(report, managerCount);
      
    } catch (e) {
      debugPrint('❌ Failed to verify email notification setup: $e');
      debugPrint('Report ID: ${report.id}, Status: ${report.status}');
      // Don't throw exception to avoid breaking report submission
    }
  }

  Future<void> _logNotificationAttempt(Report report, int managerCount) async {
    try {
      // Store notification attempt log for debugging
      final notificationLog = {
        'type': 'cloud_function_trigger',
        'reportId': report.id,
        'reportStatus': report.status,
        'locationName': report.locationName,
        'submittedBy': report.userName,
        'managerCount': managerCount,
        'timestamp': DateTime.now().toIso8601String(),
        'triggered': true, // Cloud Function was triggered
      };
      
      // Use direct Firestore instance since _firestore is private
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore.collection('notification_logs').add(notificationLog);
      debugPrint('📝 Cloud Function trigger logged for debugging');
    } catch (e) {
      debugPrint('⚠️ Failed to log notification attempt: $e');
    }
  }
}
