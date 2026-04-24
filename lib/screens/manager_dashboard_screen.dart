import 'package:flutter/material.dart';
import '../widgets/quick_action_buttons.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_drawer.dart';
import '../models/report.dart';
import '../services/firestore_service.dart';
import 'report_detail_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: const AdminDrawer(),
        appBar: AdminAppBar(
          title: 'Manager Dashboard',
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                // TODO: Implement notifications
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon')),
                );
              },
              tooltip: 'Notifications',
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Quick Actions
                const QuickActionButtons(),

                // Recent Alerts Section
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Recent Alerts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/alert_center');
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),

                // Alerts list
                SizedBox(
                  height: 400,
                  child: _buildAlertsList(),
                ),

                // Bottom padding to avoid system navigation
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildAlertsList() {
    return StreamBuilder<List<Report>>(
      stream: _firestoreService.streamReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No alerts found'));
        }

        List<Report> alerts = snapshot.data!;

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: alerts.length > 10 ? 10 : alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return _buildAlertCard(alert);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/alert_center');
                },
                child: alerts.length > 10 
                    ? Text('View More (${alerts.length - 10} more alerts)')
                    : const Text('View All Alerts'),
              ),
            ),
          ],
        );
      },
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(13),
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

  Widget _buildGuardsTab() {
    final mockGuards = [
      {'name': 'John Doe', 'email': 'john@example.com', 'status': 'active'},
      {'name': 'Jane Smith', 'email': 'jane@example.com', 'status': 'active'},
      {'name': 'Bob Johnson', 'email': 'bob@example.com', 'status': 'inactive'},
    ];

    return Column(
      children: [
        // Compact Quick Actions for Guards
        const CompactQuickActions(),
        const SizedBox(height: 16),
        
        // Guards List
        Expanded(
          child: ListView.builder(
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
                          ? Colors.green.withAlpha(25)
                          : Colors.grey.withAlpha(25),
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
          ),
        ),
      ],
    );
  }

  Widget _buildLocationsTab() {
    final mockLocations = [
      {'name': 'Site A - Main Entrance', 'address': '123 Main St', 'qrCode': 'LOC001'},
      {'name': 'Site A - Back Gate', 'address': '123 Main St', 'qrCode': 'LOC002'},
      {'name': 'Site B - Parking', 'address': '456 Oak Ave', 'qrCode': 'LOC003'},
    ];

    return Column(
      children: [
        // Compact Quick Actions for Locations
        const CompactQuickActions(),
        const SizedBox(height: 16),
        
        // Locations List
        Expanded(
          child: ListView.builder(
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
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
