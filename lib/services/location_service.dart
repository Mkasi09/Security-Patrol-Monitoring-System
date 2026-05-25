import 'dart:math' as math;

class PatrolPosition {
  final double latitude;
  final double longitude;

  const PatrolPosition({required this.latitude, required this.longitude});
}

class LocationService {
  static const double defaultRadius = 100.0; // 100 meters

  Future<bool> hasPermission() async {
    return true;
  }

  Future<bool> requestPermission() async {
    return true;
  }

  Future<PatrolPosition> getCurrentPosition() async {
    // GPS verification is intentionally disabled for now. Keep the service
    // boundary in place so native GPS can be restored without touching reports.
    return const PatrolPosition(latitude: 0.0, longitude: 0.0);
  }

  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const earthRadiusMeters = 6371000.0;
    final startLat = _toRadians(startLatitude);
    final endLat = _toRadians(endLatitude);
    final deltaLat = _toRadians(endLatitude - startLatitude);
    final deltaLng = _toRadians(endLongitude - startLongitude);

    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(startLat) *
            math.cos(endLat) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  bool isWithinRadius(
    double currentLatitude,
    double currentLongitude,
    double targetLatitude,
    double targetLongitude, {
    double radius = defaultRadius,
  }) {
    final distance = calculateDistance(
      currentLatitude,
      currentLongitude,
      targetLatitude,
      targetLongitude,
    );
    return distance <= radius;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;
}
