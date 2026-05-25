class PatrolShift {
  final String id;
  final String guardId;
  final String guardName;
  final String locationId;
  final String locationName;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
  final String notes;
  final DateTime createdAt;

  PatrolShift({
    required this.id,
    required this.guardId,
    required this.guardName,
    required this.locationId,
    required this.locationName,
    required this.startsAt,
    required this.endsAt,
    this.status = 'scheduled',
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'guardId': guardId,
      'guardName': guardName,
      'locationId': locationId,
      'locationName': locationName,
      'startsAt': startsAt.toIso8601String(),
      'endsAt': endsAt.toIso8601String(),
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PatrolShift.fromMap(Map<String, dynamic> map) {
    return PatrolShift(
      id: map['id'] ?? '',
      guardId: map['guardId'] ?? '',
      guardName: map['guardName'] ?? '',
      locationId: map['locationId'] ?? '',
      locationName: map['locationName'] ?? '',
      startsAt: DateTime.parse(
        map['startsAt'] ?? DateTime.now().toIso8601String(),
      ),
      endsAt: DateTime.parse(map['endsAt'] ?? DateTime.now().toIso8601String()),
      status: map['status'] ?? 'scheduled',
      notes: map['notes'] ?? '',
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
