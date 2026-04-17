class Report {
  final String id;
  final String userId;
  final String userName;
  final String locationId;
  final String locationName;
  final String status; // 'all_clear', 'suspicious', 'emergency'
  final String notes;
  final String? imageUrl;
  final DateTime timestamp;
  final double latitude;
  final double longitude;

  Report({
    required this.id,
    required this.userId,
    required this.userName,
    required this.locationId,
    required this.locationName,
    required this.status,
    required this.notes,
    this.imageUrl,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'locationId': locationId,
      'locationName': locationName,
      'status': status,
      'notes': notes,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      locationId: map['locationId'] ?? '',
      locationName: map['locationName'] ?? '',
      status: map['status'] ?? 'all_clear',
      notes: map['notes'] ?? '',
      imageUrl: map['imageUrl'],
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
    );
  }
}
