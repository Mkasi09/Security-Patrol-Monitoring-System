// Demo script to show auto-generation functionality
// Run this with: dart demo_auto_generation.dart

import 'lib/services/id_generator_service.dart';

void main() {
  print('=== Location ID and QR Code Auto-Generation Demo ===\n');
  
  // Reset counter for demo
  IDGeneratorService.resetCounter();
  
  print('Generating 3 sample location pairs:\n');
  
  for (int i = 1; i <= 3; i++) {
    final pair = IDGeneratorService.generateLocationPair();
    print('Sample $i:');
    print('  Location ID: ${pair['locationId']}');
    print('  QR Code:    ${pair['qrCode']}');
    print('');
  }
  
  print('Features:');
  print('  - Auto-generated unique IDs with date and counter');
  print('  - Matching location ID and QR code pairs');
  print('  - Format: loc_YYYYMMDD_NNN for location IDs');
  print('  - Format: LOC+YYYYMMDD+NNN for QR codes');
  print('  - Counter increments automatically');
  print('  - Can regenerate IDs with refresh button in UI');
  
  print('\nIntegration:');
  print('  - AdminAddLocationScreen auto-populates ID and QR code fields');
  print('  - Fields are read-only but can be regenerated');
  print('  - LocationManager.addLocationWithAutoIds() for programmatic use');
}
