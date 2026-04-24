import 'package:flutter/material.dart';
import 'dart:math';
import '../models/report.dart';
import '../services/firestore_service.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_drawer.dart';
import 'report_detail_screen.dart';

class AdminAlertScreen extends StatefulWidget {
  const AdminAlertScreen({super.key});

  @override
  State<AdminAlertScreen> createState() => _AdminAlertScreenState();
}

class _AdminAlertScreenState extends State<AdminAlertScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // Filters
  String _selectedStatusFilter = 'all';
  String _selectedLocationFilter = 'all';
  String _selectedGuardFilter = 'all';
  DateTimeRange? _dateRange;
  String _searchQuery = '';

  // Data
  List<Report> _allAlerts = [];
  List<Report> _filteredAlerts = [];
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _loadData();
  }


  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load real data from Firestore
      _allAlerts = await _firestoreService.getAllReports();

      _applyFilters();


      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  void _applyFilters() {
    _filteredAlerts = _allAlerts.where((alert) {
      // Status filter
      if (_selectedStatusFilter != 'all' && alert.status != _selectedStatusFilter) {
        return false;
      }

      // Location filter
      if (_selectedLocationFilter != 'all' && alert.locationId != _selectedLocationFilter) {
        return false;
      }

      // Guard filter
      if (_selectedGuardFilter != 'all' && alert.userId != _selectedGuardFilter) {
        return false;
      }

      // Date range filter
      if (_dateRange != null) {
        if (alert.timestamp.isBefore(_dateRange!.start) ||
            alert.timestamp.isAfter(_dateRange!.end)) {
          return false;
        }
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!alert.userName.toLowerCase().contains(query) &&
            !alert.locationName.toLowerCase().contains(query) &&
            !alert.notes.toLowerCase().contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AdminAppBar(
        title: 'Alert Center',
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportAlerts,
            tooltip: 'Export Alerts',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _buildAlertsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search alerts...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();

            },
          ),
          const SizedBox(height: 12),

          // Filter chips and date range
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all', _selectedStatusFilter == 'all', (value) {
                        setState(() {
                          _selectedStatusFilter = value;
                        });
                        _applyFilters();
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('All Clear', 'all_clear', _selectedStatusFilter == 'all_clear', (value) {
                        setState(() {
                          _selectedStatusFilter = value;
                        });
                        _applyFilters();
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Suspicious', 'suspicious', _selectedStatusFilter == 'suspicious', (value) {
                        setState(() {
                          _selectedStatusFilter = value;
                        });
                        _applyFilters();
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Emergency', 'emergency', _selectedStatusFilter == 'emergency', (value) {
                        setState(() {
                          _selectedStatusFilter = value;
                        });
                        _applyFilters();
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  _dateRange != null ? Icons.date_range : Icons.calendar_today,
                  color: _dateRange != null ? Colors.blue : null,
                ),
                onPressed: _selectDateRange,
                tooltip: _dateRange != null
                    ? '${_dateRange!.start.day}/${_dateRange!.start.month}/${_dateRange!.start.year} - ${_dateRange!.end.day}/${_dateRange!.end.month}/${_dateRange!.end.year}'
                    : 'Select date range',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isSelected, Function(String) onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => onTap(value),
      backgroundColor: Colors.white,
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue,
    );
  }


  Widget _buildAlertsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [


        // Alerts list
        Expanded(
          child: _filteredAlerts.isEmpty
              ? const Center(
            child: Text('No alerts found matching your criteria'),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredAlerts.length,
            itemBuilder: (context, index) {
              final alert = _filteredAlerts[index];
              return _buildAlertCard(alert);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(Report alert) {
    final statusColor = _getStatusColor(alert.status);
    final statusText = _getStatusText(alert.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportDetailScreen(report: alert),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDateTime(alert.timestamp),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    alert.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    alert.locationName,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                alert.notes,
                style: TextStyle(color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }



  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      _applyFilters();
    }
  }

  Future<void> _exportAlerts() async {
    // Mock export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting alerts...'),
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alerts exported successfully!'),
        backgroundColor: Colors.green,
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

  String _getStatusText(String status) {
    switch (status) {
      case 'all_clear':
        return 'All Clear';
      case 'suspicious':
        return 'Suspicious';
      case 'emergency':
        return 'Emergency';
      default:
        return 'Unknown';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
