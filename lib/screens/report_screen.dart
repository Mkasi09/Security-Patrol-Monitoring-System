import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/location_service.dart';
import '../services/firestore_service.dart';
import '../services/email_service.dart';
import '../services/alert_service.dart';
import '../services/storage_service.dart';
import '../providers/auth_provider.dart';
import '../models/report.dart';
import '../models/alert.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_app_bar.dart';
import 'package:provider/provider.dart';

class ReportScreen extends StatefulWidget {
  final String locationId;
  final String locationName;
  final String qrCode;

  const ReportScreen({
    super.key,
    required this.locationId,
    required this.locationName,
    required this.qrCode,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();
  final EmailService _emailService = EmailService();
  final AlertService _alertService = AlertService();
  final StorageService _storageService = StorageService();

  String _selectedStatus = 'all_clear';
  XFile? _selectedImage;
  bool _isSubmitting = false;
  String? _errorMessage;

  final Map<String, String> _statusOptions = {
    'all_clear': 'All Clear',
    'suspicious': 'Suspicious Activity',
    'emergency': 'Emergency',
  };

  @override
  void initState() {
    super.initState();
    // Location verification intentionally remains disabled for now.
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _storageService.pickImageFromCamera();

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _submitReport() async {
    // Location verification disabled - always true

    if (_formKey.currentState!.validate()) {
      if (_selectedStatus == 'emergency') {
        final confirmed = await _confirmEmergencySubmission();
        if (!confirmed) return;
      }

      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      try {
        // Location verification disabled - use default coordinates
        late final position;
        try {
          position = await _locationService.getCurrentPosition();
        } catch (e) {
          // If location fails, use default coordinates (center of map)
          position = const PatrolPosition(latitude: 0.0, longitude: 0.0);
        }

        // Get current user
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;

        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        final reportId = DateTime.now().millisecondsSinceEpoch.toString();
        String? imageUrl;
        if (_selectedImage != null) {
          imageUrl = await _storageService.uploadImage(
            userId: currentUser.id,
            reportId: reportId,
            image: _selectedImage!,
          );
        }

        // Create report object
        final report = Report(
          id: reportId,
          userId: currentUser.id,
          userName: currentUser.name ?? 'Unknown User',
          locationId: widget.locationId,
          locationName: widget.locationName,
          status: _selectedStatus,
          notes: _notesController.text.trim(),
          imageUrl: imageUrl,
          timestamp: DateTime.now(),
          latitude: position.latitude,
          longitude: position.longitude,
        );

        // Submit report to Firestore
        await _firestoreService.saveReport(report);

        // Create alert in alert center for managers
        await _createPatrolReportAlert(report);

        // Cloud Function will automatically send email notifications to managers
        debugPrint(
          '📧 Cloud Function will trigger automatically to notify managers',
        );
        final managerCount = await _emailService.getManagerCount();
        debugPrint(
          '👥 Found $managerCount managers in system - they will receive email alerts',
        );

        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report submitted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to submit report: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: ModernAppBar(title: 'Submit Report', showProfile: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationCard(),
              const SizedBox(height: 16),

              Text('Status', style: AppTheme.heading3),
              const SizedBox(height: 10),
              _buildStatusPicker(),
              const SizedBox(height: 20),

              Text('Notes', style: AppTheme.heading3),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe the situation...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter notes';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Text('Evidence Photo', style: AppTheme.heading3),
              const SizedBox(height: 8),
              _buildPhotoPicker(),
              const SizedBox(height: 20),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _getStatusColor(_selectedStatus),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Report',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.location_on, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.locationName, style: AppTheme.subtitle1),
                const SizedBox(height: 4),
                Text('QR: ${widget.qrCode}', style: AppTheme.caption),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppTheme.successColor),
        ],
      ),
    );
  }

  Widget _buildStatusPicker() {
    return Column(
      children: _statusOptions.entries.map((entry) {
        final selected = _selectedStatus == entry.key;
        final color = _getStatusColor(entry.key);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => setState(() => _selectedStatus = entry.key),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? color : Colors.grey.shade200,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(_getStatusIcon(entry.key), color: color),
                  const SizedBox(width: 12),
                  Expanded(child: Text(entry.value, style: AppTheme.subtitle2)),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? color : AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotoPicker() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _selectedImage != null
            ? Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedImage!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: AppTheme.errorColor,
                        ),
                        onPressed: () => setState(() => _selectedImage = null),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 46, color: Colors.grey.shade500),
                  const SizedBox(height: 8),
                  Text('Tap to take photo', style: AppTheme.subtitle2),
                  const SizedBox(height: 4),
                  Text('Optional evidence attachment', style: AppTheme.caption),
                ],
              ),
      ),
    );
  }

  Future<void> _createPatrolReportAlert(Report report) async {
    try {
      // Determine alert priority based on report status
      AlertPriority priority;
      switch (report.status) {
        case 'emergency':
          priority = AlertPriority.critical;
          break;
        case 'suspicious':
          priority = AlertPriority.high;
          break;
        case 'all_clear':
          priority = AlertPriority.low;
          break;
        default:
          priority = AlertPriority.medium;
      }

      // Create alert title and message
      String title = 'Patrol Report: ${report.locationName}';
      String message =
          '${report.userName} submitted a ${_getStatusText(report.status)} report at ${report.locationName}';
      if (report.notes.isNotEmpty) {
        message += '\n\nNotes: ${report.notes}';
      }

      await _alertService.createAlert(
        title: title,
        message: message,
        type: AlertType.security,
        priority: priority,
        locationId: report.locationId,
        locationName: report.locationName,
        guardId: report.userId,
        guardName: report.userName,
        targetUsers: ['all_managers'], // Target all managers
        isMassAlert: true,
        metadata: {
          'reportId': report.id,
          'reportStatus': report.status,
          'timestamp': report.timestamp.toIso8601String(),
        },
      );
    } catch (e) {
      // Log error but don't fail the report submission
      print('Failed to create alert: $e');
    }
  }

  Future<bool> _confirmEmergencySubmission() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit emergency report?'),
        content: const Text(
          'This will create a critical alert for managers. Submit only if immediate attention is required.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Submit Emergency'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'all_clear':
        return 'All Clear';
      case 'suspicious':
        return 'Suspicious Activity';
      case 'emergency':
        return 'Emergency';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'all_clear':
        return Colors.green;
      case 'suspicious':
        return Colors.orange;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'all_clear':
        return Icons.check_circle;
      case 'suspicious':
        return Icons.warning;
      case 'emergency':
        return Icons.emergency;
      default:
        return Icons.info;
    }
  }
}
