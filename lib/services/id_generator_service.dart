import 'dart:math';
import 'package:intl/intl.dart';

class IDGeneratorService {
  static int _locationCounter = 0;
  
  /// Generate a unique location ID with format: loc_YYYYMMDD_NNN
  static String generateLocationId() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    _locationCounter++;
    
    // Ensure 3-digit counter with leading zeros
    final counterStr = _locationCounter.toString().padLeft(3, '0');
    
    return 'loc_${dateStr}_$counterStr';
  }
  
  /// Generate a QR code string with format: LOC+YYYYMMDD+NNN
  static String generateQRCode() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    
    // Increment counter for QR code generation too
    _locationCounter++;
    
    // Ensure 3-digit counter with leading zeros
    final counterStr = _locationCounter.toString().padLeft(3, '0');
    
    return 'LOC+$dateStr+$counterStr';
  }
  
  /// Generate a random alphanumeric string for QR codes
  static String generateRandomQRCode({int length = 8}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }
  
  /// Reset the counter (useful for testing)
  static void resetCounter() {
    _locationCounter = 0;
  }
  
  /// Generate both location ID and QR code as a pair
  static Map<String, String> generateLocationPair() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    _locationCounter++;
    
    // Ensure 3-digit counter with leading zeros
    final counterStr = _locationCounter.toString().padLeft(3, '0');
    
    final locationId = 'loc_${dateStr}_$counterStr';
    final qrCode = 'LOC+$dateStr+$counterStr';
    
    return {
      'locationId': locationId,
      'qrCode': qrCode,
    };
  }
}
