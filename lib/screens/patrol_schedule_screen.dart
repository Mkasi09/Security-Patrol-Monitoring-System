import 'package:flutter/material.dart';
import '../models/location.dart';
import '../models/patrol_shift.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_drawer.dart';

class PatrolScheduleScreen extends StatefulWidget {
  const PatrolScheduleScreen({super.key});

  @override
  State<PatrolScheduleScreen> createState() => _PatrolScheduleScreenState();
}

class _PatrolScheduleScreenState extends State<PatrolScheduleScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<User> _guards = [];
  List<Location> _locations = [];
  bool _isLoadingLookups = true;

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final users = await _firestoreService.getAllUsers();
      final locations = await _firestoreService.getAllLocations();
      if (!mounted) return;
      setState(() {
        _guards = users.where((user) => user.role == 'guard').toList();
        _locations = locations;
        _isLoadingLookups = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingLookups = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load schedule data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AdminAppBar(
        title: 'Patrol Schedule',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _isLoadingLookups ? null : _showCreateShiftSheet,
            tooltip: 'Create shift',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoadingLookups ? null : _showCreateShiftSheet,
        icon: const Icon(Icons.add),
        label: const Text('Assign Patrol'),
      ),
      body: StreamBuilder<List<PatrolShift>>(
        stream: _firestoreService.streamPatrolShifts(),
        builder: (context, snapshot) {
          if (_isLoadingLookups ||
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load shifts: ${snapshot.error}'),
            );
          }

          final shifts = snapshot.data ?? [];
          final today = shifts.where(_isToday).toList();
          final upcoming = shifts
              .where((s) => s.startsAt.isAfter(DateTime.now()))
              .toList();
          final missed = shifts.where(_isMissed).toList();

          return RefreshIndicator(
            onRefresh: _loadLookups,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _metricTile(
                        'Today',
                        today.length,
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricTile(
                        'Upcoming',
                        upcoming.length,
                        AppTheme.infoColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricTile(
                        'Missed',
                        missed.length,
                        AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Assignments', style: AppTheme.heading3),
                const SizedBox(height: 12),
                if (shifts.isEmpty)
                  const _ScheduleEmptyState()
                else
                  ...shifts.map(_buildShiftCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _metricTile(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(label, style: AppTheme.caption),
        ],
      ),
    );
  }

  Widget _buildShiftCard(PatrolShift shift) {
    final status = _effectiveStatus(shift);
    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.route, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shift.locationName, style: AppTheme.subtitle1),
                      const SizedBox(height: 4),
                      Text(shift.guardName, style: AppTheme.body2),
                    ],
                  ),
                ),
                _statusPill(status, color),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_formatDate(shift.startsAt)}  ${_formatTime(shift.startsAt)} - ${_formatTime(shift.endsAt)}',
                ),
              ],
            ),
            if (shift.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(shift.notes, style: AppTheme.body2),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateShift(shift, 'missed'),
                    icon: const Icon(Icons.close),
                    label: const Text('Missed'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateShift(shift, 'completed'),
                    icon: const Icon(Icons.check),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateShiftSheet() async {
    if (_guards.isEmpty || _locations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add guards and locations before scheduling patrols.'),
        ),
      );
      return;
    }

    User selectedGuard = _guards.first;
    Location selectedLocation = _locations.first;
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay.fromDateTime(
      DateTime.now().add(const Duration(hours: 8)),
    );
    final notesController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assign Patrol', style: AppTheme.heading3),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<User>(
                    initialValue: selectedGuard,
                    decoration: const InputDecoration(labelText: 'Guard'),
                    items: _guards.map((guard) {
                      return DropdownMenuItem(
                        value: guard,
                        child: Text(guard.name),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setSheetState(() => selectedGuard = value!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Location>(
                    initialValue: selectedLocation,
                    decoration: const InputDecoration(labelText: 'Location'),
                    items: _locations.map((location) {
                      return DropdownMenuItem(
                        value: location,
                        child: Text(location.name),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setSheetState(() => selectedLocation = value!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 1),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              initialDate: selectedDate,
                            );
                            if (picked != null) {
                              setSheetState(() => selectedDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_formatDate(selectedDate)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: startTime,
                            );
                            if (picked != null) {
                              setSheetState(() => startTime = picked);
                            }
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: Text(startTime.format(context)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: endTime,
                            );
                            if (picked != null) {
                              setSheetState(() => endTime = picked);
                            }
                          },
                          icon: const Icon(Icons.stop),
                          label: Text(endTime.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Gate route, instructions, supervisor notes',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final startsAt = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          startTime.hour,
                          startTime.minute,
                        );
                        var endsAt = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          endTime.hour,
                          endTime.minute,
                        );
                        if (!endsAt.isAfter(startsAt)) {
                          endsAt = endsAt.add(const Duration(days: 1));
                        }

                        final id =
                            'shift_${DateTime.now().millisecondsSinceEpoch}';
                        await _firestoreService.savePatrolShift(
                          PatrolShift(
                            id: id,
                            guardId: selectedGuard.id,
                            guardName: selectedGuard.name,
                            locationId: selectedLocation.id,
                            locationName: selectedLocation.name,
                            startsAt: startsAt,
                            endsAt: endsAt,
                            notes: notesController.text.trim(),
                            createdAt: DateTime.now(),
                          ),
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.assignment_turned_in),
                      label: const Text('Create Assignment'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    notesController.dispose();
  }

  Future<void> _updateShift(PatrolShift shift, String status) async {
    await _firestoreService.updatePatrolShiftStatus(shift.id, status);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Shift marked $status')));
  }

  bool _isToday(PatrolShift shift) {
    final now = DateTime.now();
    return shift.startsAt.year == now.year &&
        shift.startsAt.month == now.month &&
        shift.startsAt.day == now.day;
  }

  bool _isMissed(PatrolShift shift) {
    return _effectiveStatus(shift) == 'missed';
  }

  String _effectiveStatus(PatrolShift shift) {
    if (shift.status == 'scheduled' && shift.endsAt.isBefore(DateTime.now())) {
      return 'missed';
    }
    return shift.status;
  }

  Widget _statusPill(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.successColor;
      case 'missed':
        return AppTheme.errorColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ScheduleEmptyState extends StatelessWidget {
  const _ScheduleEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available,
            size: 56,
            color: AppTheme.primaryColor.withValues(alpha: 0.75),
          ),
          const SizedBox(height: 12),
          Text('No patrols scheduled', style: AppTheme.heading3),
          const SizedBox(height: 6),
          Text(
            'Create assignments for guards so managers can see expected patrol coverage.',
            textAlign: TextAlign.center,
            style: AppTheme.body2,
          ),
        ],
      ),
    );
  }
}
