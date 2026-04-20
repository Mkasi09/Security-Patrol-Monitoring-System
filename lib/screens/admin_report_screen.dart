import 'package:flutter/material.dart';
import 'dart:math';
import '../models/report.dart';
import '../services/firestore_service.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_drawer.dart';
import 'report_detail_screen.dart';

class AdminReportScreen extends StatefulWidget {
  const AdminReportScreen({super.key});

  @override
  State<AdminReportScreen> createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  
  // Filters
  String _selectedStatusFilter = 'all';
  String _selectedLocationFilter = 'all';
  String _selectedGuardFilter = 'all';
  DateTimeRange? _dateRange;
  String _searchQuery = '';
  
  // Data
  List<Report> _allReports = [];
  List<Report> _filteredReports = [];
  bool _isLoading = true;
  
  // Analytics data
  Map<String, int> _statusCounts = {};
  Map<String, int> _locationCounts = {};
  Map<String, int> _guardCounts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load real data from Firestore
      _allReports = await _firestoreService.getAllReports();
      
      _applyFilters();
      _calculateAnalytics();
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  void _applyFilters() {
    _filteredReports = _allReports.where((report) {
      // Status filter
      if (_selectedStatusFilter != 'all' && report.status != _selectedStatusFilter) {
        return false;
      }
      
      // Location filter
      if (_selectedLocationFilter != 'all' && report.locationId != _selectedLocationFilter) {
        return false;
      }
      
      // Guard filter
      if (_selectedGuardFilter != 'all' && report.userId != _selectedGuardFilter) {
        return false;
      }
      
      // Date range filter
      if (_dateRange != null) {
        if (report.timestamp.isBefore(_dateRange!.start) || 
            report.timestamp.isAfter(_dateRange!.end)) {
          return false;
        }
      }
      
      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!report.userName.toLowerCase().contains(query) &&
            !report.locationName.toLowerCase().contains(query) &&
            !report.notes.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  void _calculateAnalytics() {
    _statusCounts.clear();
    _locationCounts.clear();
    _guardCounts.clear();
    
    for (final report in _filteredReports) {
      _statusCounts[report.status] = (_statusCounts[report.status] ?? 0) + 1;
      _locationCounts[report.locationName] = (_locationCounts[report.locationName] ?? 0) + 1;
      _guardCounts[report.userName] = (_guardCounts[report.userName] ?? 0) + 1;
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AdminAppBar(
        title: 'Admin Reports',
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReports,
            tooltip: 'Export Reports',
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
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReportsTab(),
                _buildAnalyticsTab(),
                _buildChartsTab(),
              ],
            ),
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
              hintText: 'Search reports...',
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
              _calculateAnalytics();
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
                        _calculateAnalytics();
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('All Clear', 'all_clear', _selectedStatusFilter == 'all_clear', (value) {
                        setState(() {
                          _selectedStatusFilter = value;
                        });
                        _applyFilters();
                        _calculateAnalytics();
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Suspicious', 'suspicious', _selectedStatusFilter == 'suspicious', (value) {
                        setState(() {
                          _selectedStatusFilter = value;
                        });
                        _applyFilters();
                        _calculateAnalytics();
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Emergency', 'emergency', _selectedStatusFilter == 'emergency', (value) {
                        setState(() {
                          _selectedStatusFilter = value;
                        });
                        _applyFilters();
                        _calculateAnalytics();
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

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Reports', icon: Icon(Icons.list)),
        Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
        Tab(text: 'Charts', icon: Icon(Icons.bar_chart)),
      ],
    );
  }

  Widget _buildReportsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Summary cards
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _buildSummaryCard('Total Reports', _filteredReports.length, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard('Emergency', _statusCounts['emergency'] ?? 0, Colors.red)),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard('Suspicious', _statusCounts['suspicious'] ?? 0, Colors.orange)),
            ],
          ),
        ),
        
        // Reports list
        Expanded(
          child: _filteredReports.isEmpty
              ? const Center(
                  child: Text('No reports found matching your criteria'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredReports.length,
                  itemBuilder: (context, index) {
                    final report = _filteredReports[index];
                    return _buildReportCard(report);
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

  Widget _buildReportCard(Report report) {
    final statusColor = _getStatusColor(report.status);
    final statusText = _getStatusText(report.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportDetailScreen(report: report),
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
                    _formatDateTime(report.timestamp),
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
                    report.userName,
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
                    report.locationName,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.notes,
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

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report Analytics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Status breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Breakdown',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._statusCounts.entries.map((entry) {
                    final percentage = _filteredReports.isNotEmpty 
                        ? (entry.value / _filteredReports.length * 100).toStringAsFixed(1)
                        : '0.0';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getStatusColor(entry.key),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_getStatusText(entry.key)),
                          ),
                          Text('$percentage%'),
                          const SizedBox(width: 8),
                          Text(
                            entry.value.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Top locations
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Locations',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...(_locationCounts.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value))
                    ..take(5)).map((entry) {
                      final percentage = _filteredReports.isNotEmpty 
                          ? (entry.value / _filteredReports.length * 100).toStringAsFixed(1)
                          : '0.0';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text(entry.key)),
                            Text('$percentage%'),
                            const SizedBox(width: 8),
                            Text(
                              entry.value.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Top guards
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Guards',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...(_guardCounts.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value))
                    ..take(5)).map((entry) {
                      final percentage = _filteredReports.isNotEmpty 
                          ? (entry.value / _filteredReports.length * 100).toStringAsFixed(1)
                          : '0.0';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text(entry.key)),
                            Text('$percentage%'),
                            const SizedBox(width: 8),
                            Text(
                              entry.value.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Visual Analytics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Simple bar chart for status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Distribution',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildStatusBarChart(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Simple pie chart representation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Overview',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildPieChartRepresentation(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBarChart() {
    final maxValue = _statusCounts.values.isNotEmpty ? _statusCounts.values.reduce(max) : 1;
    
    return Column(
      children: _statusCounts.entries.map((entry) {
        final percentage = maxValue > 0 ? entry.value / maxValue : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_getStatusText(entry.key)),
                  Text(entry.value.toString()),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getStatusColor(entry.key),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPieChartRepresentation() {
    final total = _filteredReports.length;
    if (total == 0) {
      return const Center(child: Text('No data available'));
    }
    
    return Column(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            children: [
              // Simple pie chart using containers
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                ),
              ),
              // This is a simplified representation - in a real app you'd use a charting library
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      total.toString(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Text('Total Reports'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._statusCounts.entries.map((entry) {
          final percentage = (entry.value / total * 100).toStringAsFixed(1);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getStatusColor(entry.key),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(_getStatusText(entry.key))),
                Text('$percentage%'),
              ],
            ),
          );
        }),
      ],
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
      _calculateAnalytics();
    }
  }

  Future<void> _exportReports() async {
    // Mock export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting reports...'),
        duration: Duration(seconds: 2),
      ),
    );
    
    await Future.delayed(const Duration(seconds: 2));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reports exported successfully!'),
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
