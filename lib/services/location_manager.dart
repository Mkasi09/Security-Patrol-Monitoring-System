import '../models/location.dart';
import 'firestore_service.dart';

class LocationManager {
  final FirestoreService _firestoreService = FirestoreService();

  /// Add sample locations to Firestore
  /// Call this method to populate your database with initial locations
  Future<void> addSampleLocations() async {
    final locations = [
      Location(
        id: 'loc_001',
        name: 'Site A - Main Entrance',
        address: '123 Security Street, Building A',
        qrCode: 'LOC001',
        latitude: 40.7128,
        longitude: -74.0060,
        radius: 100.0,
      ),
      Location(
        id: 'loc_002',
        name: 'Site A - Parking Lot',
        address: '123 Security Street, Parking Area',
        qrCode: 'LOC002',
        latitude: 40.7130,
        longitude: -74.0065,
        radius: 150.0,
      ),
      Location(
        id: 'loc_003',
        name: 'Site B - Lobby',
        address: '456 Guard Avenue, Building B',
        qrCode: 'LOC003',
        latitude: 40.7140,
        longitude: -74.0070,
        radius: 100.0,
      ),
      Location(
        id: 'loc_004',
        name: 'Site B - Server Room',
        address: '456 Guard Avenue, Building B, Floor 2',
        qrCode: 'LOC004',
        latitude: 40.7142,
        longitude: -74.0072,
        radius: 50.0,
      ),
      Location(
        id: 'loc_005',
        name: 'Site C - Warehouse',
        address: '789 Patrol Road, Warehouse 1',
        qrCode: 'LOC005',
        latitude: 40.7150,
        longitude: -74.0080,
        radius: 200.0,
      ),
    ];

    for (final location in locations) {
      await _firestoreService.saveLocation(location);
    }

  }

  /// Add a single custom location
  Future<void> addCustomLocation({
    required String id,
    required String name,
    required String address,
    required String qrCode,
    required double latitude,
    required double longitude,
    double radius = 100.0,
  }) async {
    final location = Location(
      id: id,
      name: name,
      address: address,
      qrCode: qrCode,
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );

    await _firestoreService.saveLocation(location);
  }
}
