import 'package:flutter/material.dart';
import '../models/report.dart';
import '../models/user.dart';
import 'firestore_service.dart';

class EmailService {
  final FirestoreService _firestoreService = FirestoreService();

  /// Send email notification to manager when a report is submitted
  Future<void> sendReportNotificationToManager(Report report) async {
    try {
      // Get all users to find managers
      final users = await _firestoreService.getAllUsers();
      
      // Filter for managers
      final managers = users.where((user) => user.role == 'manager').toList();
      
      if (managers.isEmpty) {
        debugPrint('No managers found to send notification');
        return;
      }

      // Prepare email content
      final subject = 'New Patrol Report Submitted - ${report.status.toUpperCase()}';
      
      final emailBody = _buildEmailBody(report);

      // In a real implementation, you would use an email service like:
      // - SendGrid
      // - Firebase Functions
      // - AWS SES
      // - SMTP configuration
      
      // For now, we'll simulate the email sending
      await _simulateEmailSend(managers, subject, emailBody);
      
      debugPrint('Email notification sent to ${managers.length} managers');
      
    } catch (e) {
      debugPrint('Failed to send email notification: $e');
      // Don't throw exception to avoid breaking report submission
    }
  }

  String _buildEmailBody(Report report) {
    final buffer = StringBuffer();
    
    buffer.writeln('SECURITY PATROL REPORT NOTIFICATION');
    buffer.writeln('=' * 50);
    buffer.writeln();
    buffer.writeln('Report Details:');
    buffer.writeln('- Location: ${report.locationName}');
    buffer.writeln('- Status: ${_getStatusDisplay(report.status)}');
    buffer.writeln('- Submitted by: ${report.userName}');
    buffer.writeln('- Date & Time: ${report.timestamp}');
    buffer.writeln('- GPS Coordinates: ${report.latitude}, ${report.longitude}');
    
    if (report.notes.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Notes:');
      buffer.writeln(report.notes);
    }
    
    if (report.imageUrl != null) {
      buffer.writeln();
      buffer.writeln('Photo: Available');
    }
    
    buffer.writeln();
    buffer.writeln('=' * 50);
    buffer.writeln('This is an automated notification from the Security Patrol Monitoring System.');
    buffer.writeln('Please log in to view detailed information.');
    
    return buffer.toString();
  }

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'all_clear':
        return 'All Clear';
      case 'suspicious':
        return 'Suspicious Activity';
      case 'emergency':
        return 'Emergency';
      default:
        return status;
    }
  }

  Future<void> _simulateEmailSend(List<User> managers, String subject, String body) async {
    // Simulate email sending delay
    await Future.delayed(const Duration(seconds: 2));
    
    for (final manager in managers) {
      debugPrint('Email sent to: ${manager.email}');
      debugPrint('Subject: $subject');
      debugPrint('Body preview: ${body.substring(0, 100)}...');
    }
    
    // TODO: Implement actual email service integration
    // Options for real implementation:
    // 1. Firebase Cloud Functions with SendGrid
    // 2. AWS SES with SMTP
    // 3. Firebase Extensions for email
    // 4. Third-party email service like Mailgun
  }
}
