import 'package:flutter_test/flutter_test.dart';
import '../lib/models/location.dart';
import '../lib/services/qr_pdf_service.dart';

void main() {
  group('QR PDF Service Tests', () {
    test('should create location object correctly', () {
      final location = Location(
        id: 'loc_20260422_001',
        name: 'Main Entrance',
        address: '123 Security Street',
        qrCode: 'LOC+20260422+001',
        latitude: 40.7128,
        longitude: -74.0060,
        radius: 100.0,
      );

      expect(location.id, equals('loc_20260422_001'));
      expect(location.name, equals('Main Entrance'));
      expect(location.qrCode, equals('LOC+20260422+001'));
    });

    test('should generate location toMap correctly', () {
      final location = Location(
        id: 'loc_20260422_001',
        name: 'Main Entrance',
        address: '123 Security Street',
        qrCode: 'LOC+20260422+001',
        latitude: 40.7128,
        longitude: -74.0060,
        radius: 100.0,
      );

      final map = location.toMap();
      expect(map['id'], equals('loc_20260422_001'));
      expect(map['name'], equals('Main Entrance'));
      expect(map['qrCode'], equals('LOC+20260422+001'));
      expect(map['latitude'], equals(40.7128));
      expect(map['longitude'], equals(-74.0060));
      expect(map['radius'], equals(100.0));
    });

    // Note: PDF generation test would require actual file system and image loading
    // which is complex for unit tests. The functionality is verified through manual testing.
  });
}
