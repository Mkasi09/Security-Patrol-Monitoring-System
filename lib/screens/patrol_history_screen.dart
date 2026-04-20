import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/report.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/modern_app_bar.dart';
import 'package:provider/provider.dart';
import 'report_detail_screen.dart';

class PatrolHistoryScreen extends StatefulWidget {
  const PatrolHistoryScreen({super.key});

  @override
  State<PatrolHistoryScreen> createState() => _PatrolHistoryScreenState();
}

class _PatrolHistoryScreenState extends State<PatrolHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Report> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filtering options
  String _selectedStatus = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedLocation = 'all';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        final reports = await _firestoreService.getReportsByUserId(user.id);
        setState(() {
          _reports = _filterReports(reports);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load reports: $e';
      });
    }
  }

  List<Report> _filterReports(List<Report> reports) {
    List<Report> filtered = List.from(reports);

    // Filter by status
    if (_selectedStatus != 'all') {
      filtered = filtered.where((report) => report.status == _selectedStatus).toList();
    }

    // Filter by date range
    if (_startDate != null) {
      filtered = filtered.where((report) => report.timestamp.isAfter(_startDate!)).toList();
    }
    if (_endDate != null) {
      filtered = filtered.where((report) => report.timestamp.isBefore(_endDate!.add(const Duration(days: 1)))).toList();
    }

    // Filter by location
    if (_selectedLocation != 'all') {
      filtered = filtered.where((report) => report.locationName == _selectedLocation).toList();
    }

    return filtered;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Reports'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status filter
                const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Status')),
                    DropdownMenuItem(value: 'all_clear', child: Text('All Clear')),
                    DropdownMenuItem(value: 'suspicious', child: Text('Suspicious')),
                    DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Start date filter
                const Text('Start Date', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(_startDate != null 
                    ? DateFormat('MMM dd, yyyy').format(_startDate!)
                    : 'Select start date'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // End date filter
                const Text('End Date', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(_endDate != null 
                    ? DateFormat('MMM dd, yyyy').format(_endDate!)
                    : 'Select end date'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Location filter
                const Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All Locations')),
                    ..._getLocationOptions().map((location) => 
                      DropdownMenuItem(value: location, child: Text(location))),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedLocation = value!);
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = 'all';
                _startDate = null;
                _endDate = null;
                _selectedLocation = 'all';
              });
            },
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadReports();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  List<String> _getLocationOptions() {
    final locations = _reports.map((report) => report.locationName).toSet().toList();
    locations.sort();
    return locations;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadReports,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _reports.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No patrol reports found', style: TextStyle(fontSize: 18)),
                          SizedBox(height: 8),
                          Text('Start scanning locations to build your history', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reports.length,
                      itemBuilder: (context, index) {
                        final report = _reports[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(report.status).withOpacity(0.2),
                              child: Icon(
                                _getStatusIcon(report.status),
                                color: _getStatusColor(report.status),
                              ),
                            ),
                            title: Text(
                              report.locationName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getStatusDisplay(report.status),
                                  style: TextStyle(
                                    color: _getStatusColor(report.status),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM dd, yyyy - hh:mm a').format(report.timestamp),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReportDetailScreen(report: report),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'all_clear':
        return Icons.check_circle;
      case 'suspicious':
        return Icons.warning;
      case 'emergency':
        return Icons.error;
      default:
        return Icons.info;
    }
  }
}
