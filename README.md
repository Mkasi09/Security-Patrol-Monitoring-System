# Security Patrol Monitoring System

A mobile application designed for security companies to track and manage guard patrol activities. The system allows security guards to scan QR codes placed at specific locations, submit reports, and provide real-time updates to managers.

## Features

### For Security Guards
- **QR Code Scanning**: Scan unique QR codes at patrol locations
- **GPS Location Verification**: System verifies guards are physically at assigned locations
- **Patrol Reporting**: Submit reports with status (All Clear, Suspicious Activity, Emergency)
- **Image Upload**: Attach photos as evidence for reports
- **Timestamp Logging**: Automatic date/time logging for all activities

### For Managers
- **Real-time Dashboard**: View all patrol reports in real-time
- **Filtering**: Filter reports by date, guard, location, and status
- **Guard Monitoring**: Track guard activity and patrol history
- **Location Management**: View and manage patrol locations
- **Alerts**: Receive notifications for emergency reports

## Tech Stack

- **Frontend**: Flutter
- **State Management**: Provider
- **Backend**: Firebase (Authentication, Firestore, Storage, Cloud Messaging)
- **QR Scanning**: mobile_scanner
- **Location Services**: geolocator
- **Image Handling**: image_picker

## Prerequisites

- Flutter SDK (3.11.0 or higher)
- Dart SDK
- Android Studio / Xcode
- Firebase account
- Physical device or emulator with camera support

## Installation

### 1. Clone the repository
```bash
git clone <repository-url>
cd magzmotron
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Firebase Setup

#### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Enable the following services:
   - Authentication (Email/Password)
   - Firestore Database
   - Storage
   - Cloud Messaging

#### Configure Android
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/`
3. Add the classpath to `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```
4. Add the plugin to `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

#### Configure iOS
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in `ios/Runner/`
3. Add Firebase SDK to `ios/Podfile` if needed

### 4. Run the app
```bash
flutter run
```

## Project Structure

```bash
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user.dart
│   ├── location.dart
│   └── report.dart
├── services/                 # Business logic
│   ├── auth_service.dart
│   ├── location_service.dart
│   └── storage_service.dart
├── providers/                 # State management
│   └── auth_provider.dart
└── screens/                   # UI screens
    ├── login_screen.dart
    ├── guard_home_screen.dart
    ├── manager_dashboard_screen.dart
    ├── qr_scanner_screen.dart
    └── report_screen.dart
```

## Usage

### Guard Workflow
1. **Login**: Enter email and password
2. **Scan QR Code**: Tap "Scan QR Code" and scan location QR code
3. **Location Verification**: System verifies GPS location
4. **Submit Report**: Select status, add notes, optionally attach photo
5. **Confirmation**: Report is saved and manager is notified

### Manager Workflow
1. **Login**: Enter email and password
2. **View Dashboard**: Access reports, guards, and locations tabs
3. **Filter Reports**: Use status and date filters
4. **Monitor Activity**: View real-time patrol activities
5. **View Details**: Tap on reports to see full details

## Permissions

The app requires the following permissions:

### Android
- `CAMERA`: For QR code scanning and photo capture
- `ACCESS_FINE_LOCATION`: For GPS verification
- `ACCESS_COARSE_LOCATION`: For location services
- `INTERNET`: For Firebase connectivity

### iOS
- `NSCameraUsageDescription`: Camera access for QR scanning and photos
- `NSLocationWhenInUseUsageDescription`: Location access for verification
- `NSLocationAlwaysUsageDescription`: Background location access

## Data Models

### User
- id: String
- name: String
- email: String
- role: String ('guard' or 'manager')
- phoneNumber: String?

### Location
- id: String
- name: String
- address: String
- qrCode: String
- latitude: double
- longitude: double
- radius: double (GPS verification radius in meters)

### Report
- id: String
- userId: String
- userName: String
- locationId: String
- locationName: String
- status: String ('all_clear', 'suspicious', 'emergency')
- notes: String
- imageUrl: String?
- timestamp: DateTime
- latitude: double
- longitude: double

## Security Features

- **GPS Verification**: Prevents fake check-ins by verifying location
- **Role-based Access**: Separate interfaces for guards and managers
- **Secure Authentication**: Firebase Auth with email/password
- **Encrypted Data**: Firebase provides encryption for data at rest and in transit

## Future Enhancements

- Offline mode support
- Push notifications for managers
- Route planning for guards
- Analytics and reporting
- Multi-language support
- Dark mode

## Troubleshooting

### Camera not working
- Ensure camera permission is granted
- Test on a physical device (emulator camera may not work)
- Check if camera is being used by another app

### Location verification fails
- Ensure location permissions are granted
- Check if location services are enabled
- Test outdoors for better GPS accuracy

### Firebase connection issues
- Verify Firebase configuration files are in correct locations
- Check internet connection
- Ensure Firebase services are enabled in console

## License

This project is proprietary software for security patrol monitoring.
