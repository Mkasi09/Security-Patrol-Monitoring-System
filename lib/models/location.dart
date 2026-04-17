class Location {
  final String id;
  final String name;
  final String address;
  final String qrCode;
  final double latitude;
  final double longitude;
  final double radius; // GPS verification radius in meters

  Location({
    required this.id,
    required this.name,
    required this.address,
    required this.qrCode,
    required this.latitude,
    required this.longitude,
    this.radius = 100.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'qrCode': qrCode,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      qrCode: map['qrCode'] ?? '',
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      radius: map['radius'] ?? 100.0,
    );
  }
}
