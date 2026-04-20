import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';
import '../models/location.dart';
import '../models/user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= REPORTS =================

  Future<void> saveReport(Report report) async {
    try {
      await _firestore
          .collection('reports')
          .doc(report.id)
          .set(report.toMap());
    } catch (e) {
      throw Exception('Failed to save report: $e');
    }
  }

  Future<List<Report>> getReportsByUserId(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Report.fromMap({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  Stream<List<Report>> streamReports() {
    return _firestore
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      return Report.fromMap({
        ...doc.data(),
        'id': doc.id,
      });
    }).toList());
  }

  Future<List<Report>> getAllReports() async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Report.fromMap({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch all reports: $e');
    }
  }

  // ================= LOCATIONS =================

  Future<Location?> getLocationByQRCode(String qrCode) async {
    try {
      final snapshot = await _firestore
          .collection('locations')
          .where('qrCode', isEqualTo: qrCode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Location.fromMap({
          ...snapshot.docs.first.data(),
          'id': snapshot.docs.first.id,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch location: $e');
    }
  }

  Future<List<Location>> getAllLocations() async {
    try {
      final snapshot = await _firestore.collection('locations').get();

      return snapshot.docs.map((doc) {
        return Location.fromMap({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch locations: $e');
    }
  }

  Future<void> saveLocation(Location location) async {
    try {
      await _firestore
          .collection('locations')
          .doc(location.id)
          .set(location.toMap());
    } catch (e) {
      throw Exception('Failed to save location: $e');
    }
  }

  // ================= USERS =================

  Future<void> saveUser(User user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toMap());
    } catch (e) {
      throw Exception('Failed to save user: $e');
    }
  }

  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        return User.fromMap({
          ...doc.data()!,
          'id': doc.id,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return User.fromMap({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> updateUserPasswordResetStatus(
      String userId, bool hasResetPassword) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'hasResetPassword': hasResetPassword,
      });
    } catch (e) {
      throw Exception('Failed to update reset status: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }
}