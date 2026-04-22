import 'package:flutter_test/flutter_test.dart';
import '../lib/services/id_generator_service.dart';

void main() {
  group('IDGeneratorService Tests', () {
    setUp(() {
      // Reset counter before each test to ensure predictable results
      IDGeneratorService.resetCounter();
    });

    test('should generate unique location IDs', () {
      final id1 = IDGeneratorService.generateLocationId();
      final id2 = IDGeneratorService.generateLocationId();
      
      expect(id1, isNot(equals(id2)));
      expect(id1, startsWith('loc_'));
      expect(id2, startsWith('loc_'));
    });

    test('should generate unique QR codes', () {
      final qr1 = IDGeneratorService.generateQRCode();
      final qr2 = IDGeneratorService.generateQRCode();
      
      expect(qr1, isNot(equals(qr2)));
      expect(qr1, startsWith('LOC+'));
      expect(qr2, startsWith('LOC+'));
    });

    test('should generate matching pairs', () {
      final pair1 = IDGeneratorService.generateLocationPair();
      final pair2 = IDGeneratorService.generateLocationPair();
      
      expect(pair1['locationId'], isNot(equals(pair2['locationId'])));
      expect(pair1['qrCode'], isNot(equals(pair2['qrCode'])));
      
      // Verify format
      expect(pair1['locationId']!, matches(RegExp(r'loc_\d{8}_\d{3}')));
      expect(pair1['qrCode']!, matches(RegExp(r'LOC\+\d{8}\+\d{3}')));
    });

    test('should generate random QR codes of specified length', () {
      final qr1 = IDGeneratorService.generateRandomQRCode(length: 8);
      final qr2 = IDGeneratorService.generateRandomQRCode(length: 12);
      
      expect(qr1.length, equals(8));
      expect(qr2.length, equals(12));
      expect(qr1, matches(RegExp(r'^[A-Z0-9]{8}$')));
      expect(qr2, matches(RegExp(r'^[A-Z0-9]{12}$')));
    });
  });
}
