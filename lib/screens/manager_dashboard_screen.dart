import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  String _selectedFilter = 'all';
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manager Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await authProvider.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Reports'),
              Tab(text: 'Guards'),
              Tab(text: 'Locations'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildReportsTab(),
            _buildGuardsTab(),
            _buildLocationsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'all_clear', child: Text('All Clear')),
                    DropdownMenuItem(value: 'suspicious', child: Text('Suspicious')),
                    DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  _selectedDate != null ? Icons.event : Icons.calendar_today,
                  color: _selectedDate != null ? Colors.blue : null,
                ),
                tooltip: _selectedDate != null 
                    ? 'Filter by date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                    : 'Filter by date',
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  } else if (_selectedDate != null) {
                    setState(() {
                      _selectedDate = null;
                    });
                  }
                },
              ),
            ],
          ),
        ),

        // Reports list
        Expanded(
          child: _buildReportsList(),
        ),
      ],
    );
  }

  Widget _buildReportsList() {
    // Mock data - in real app, fetch from Firestore
    final mockReports = [
      {
        'id': '1',
        'guardName': 'John Doe',
        'location': 'Site A - Main Entrance',
        'status': 'all_clear',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'notes': 'Regular patrol completed',
      },
      {
        'id': '2',
        'guardName': 'Jane Smith',
        'location': 'Site B - Parking',
        'status': 'suspicious',
        'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
        'notes': 'Unknown vehicle spotted',
      },
      {
        'id': '3',
        'guardName': 'John Doe',
        'location': 'Site A - Back Gate',
        'status': 'emergency',
        'timestamp': DateTime.now().subtract(const Duration(hours: 6)),
        'notes': 'Break-in attempt reported',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: mockReports.length,
      itemBuilder: (context, index) {
        final report = mockReports[index];
        return _buildReportCard(report);
      },
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final status = report['status'] as String;
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _showReportDetails(report);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                    _formatDateTime(report['timestamp'] as DateTime),
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
                    report['guardName'] as String,
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
                    report['location'] as String,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report['notes'] as String,
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

  Widget _buildGuardsTab() {
    final mockGuards = [
      {'name': 'John Doe', 'email': 'john@example.com', 'status': 'active'},
      {'name': 'Jane Smith', 'email': 'jane@example.com', 'status': 'active'},
      {'name': 'Bob Johnson', 'email': 'bob@example.com', 'status': 'inactive'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockGuards.length,
      itemBuilder: (context, index) {
        final guard = mockGuards[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(guard['name']![0]),
            ),
            title: Text(guard['name'] as String),
            subtitle: Text(guard['email'] as String),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: guard['status'] == 'active'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                guard['status'] as String,
                style: TextStyle(
                  color: guard['status'] == 'active' ? Colors.green : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationsTab() {
    final mockLocations = [
      {'name': 'Site A - Main Entrance', 'address': '123 Main St', 'qrCode': 'LOC001'},
      {'name': 'Site A - Back Gate', 'address': '123 Main St', 'qrCode': 'LOC002'},
      {'name': 'Site B - Parking', 'address': '456 Oak Ave', 'qrCode': 'LOC003'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockLocations.length,
      itemBuilder: (context, index) {
        final location = mockLocations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.location_on, color: Colors.white),
            ),
            title: Text(location['name'] as String),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location['address'] as String),
                Text(
                  'QR: ${location['qrCode']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Guard', report['guardName']),
              _buildDetailRow('Location', report['location']),
              _buildDetailRow('Status', _getStatusText(report['status'])),
              _buildDetailRow('Time', _formatDateTime(report['timestamp'])),
              const SizedBox(height: 12),
              const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(report['notes']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
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
