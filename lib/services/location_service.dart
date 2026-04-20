import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static const double defaultRadius = 100.0; // 100 meters

  Future<bool> hasPermission() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  Future<bool> requestPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  Future<Position> getCurrentPosition() async {
    final hasPermission = await this.hasPermission();
    if (!hasPermission) {
      final granted = await requestPermission();
      if (!granted) {
        throw Exception('Location permission denied');
      }
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    );
  }

  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
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
}
