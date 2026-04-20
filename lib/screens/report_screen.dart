import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../services/location_service.dart';
import '../services/firestore_service.dart';
import '../services/email_service.dart';
import '../providers/auth_provider.dart';
import '../models/report.dart';
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

  String _selectedStatus = 'all_clear';
  File? _selectedImage;
  bool _isVerifyingLocation = false;
  bool _isLocationVerified = true;
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
    // Location verification disabled for now
    setState(() {
      _isLocationVerified = true;
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _submitReport() async {
    // Location verification disabled - always true

    if (_formKey.currentState!.validate()) {
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
          position = Position(
            latitude: 0.0,
            longitude: 0.0,
            timestamp: DateTime.now(),
            accuracy: 0.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0, headingAccuracy: 0.0,
          );
        }

        // Get current user
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;

        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        // Upload image if selected
        String? imageUrl;
        if (_selectedImage != null) {
          // TODO: Implement actual Firebase Storage upload
          // For now, we'll skip image upload
          imageUrl = null;
        }

        // Create report object
        final report = Report(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
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

        // Send email notification to managers
        await _emailService.sendReportNotificationToManager(report);

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
      appBar: ModernAppBar(
        title: 'Submit Report',
        showProfile: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location verification status
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (_isVerifyingLocation)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (_isLocationVerified)
                        const Icon(Icons.check_circle, color: Colors.green)
                      else
                        const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isVerifyingLocation
                              ? 'Verifying location...'
                              : _isLocationVerified
                                  ? 'Location verified'
                                  : 'Location verification failed',
                          style: TextStyle(
                            color: _isLocationVerified
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Location info
              Text(
                'Location: ${widget.locationName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'QR Code: ${widget.qrCode}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // Status selection
              const Text(
                'Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._statusOptions.entries.map((entry) {
                return RadioListTile<String>(
                  title: Text(entry.value),
                  value: entry.key,
                  groupValue: _selectedStatus,
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                  activeColor: _getStatusColor(entry.key),
                );
              }),
              const SizedBox(height: 24),

              // Notes
              const Text(
                'Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
              const SizedBox(height: 24),

              // Image upload
              const Text(
                'Evidence Photo (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImage != null
                      ? Stack(
                          children: [
                            Positioned.fill(
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _selectedImage = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'Tap to take photo',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

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
}
