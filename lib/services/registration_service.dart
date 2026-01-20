import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/registration_model.dart';
import 'firebase_auth_service.dart';
import 'event_service.dart';

class RegistrationService {
  static final RegistrationService _instance = RegistrationService._internal();

  factory RegistrationService() {
    return _instance;
  }

  RegistrationService._internal() {
    _firestore = FirebaseFirestore.instance;
  }

  late final FirebaseFirestore _firestore;

  Future<bool> registerEvent(String userId, String eventId) async {
    try {
      // Check existing non-cancelled registration in Firestore
      final existing = await _firestore
          .collection('registrations')
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .get();
      for (final doc in existing.docs) {
        final data = doc.data();
        if ((data['status'] ?? 'confirmed') != 'cancelled') {
          return false;
        }
      }

      final auth = FirebaseAuthService();
      final userData = await auth.getUserData(userId);
      final email = auth.currentUser?.email ?? (userData?['email'] ?? '');
      final fullName = userData?['fullName'] ?? auth.currentUser?.displayName ?? '';
      final nim = userData?['nim'] ?? '';
      final phoneNumber = userData?['phoneNumber'] ?? '';
      final faculty = userData?['faculty'] ?? '';

      final event = await EventService().getEventById(eventId);
      final title = event?.title ?? '';

      final registrationId = 'reg_${DateTime.now().millisecondsSinceEpoch}';
      final record = {
        'id': registrationId,
        'userId': userId,
        'eventId': eventId,
        'eventTitle': title,
        'fullName': fullName,
        'email': email,
        'nim': nim,
        'phoneNumber': phoneNumber,
        'faculty': faculty,
        'registeredAt': FieldValue.serverTimestamp(),
        'status': 'confirmed',
      };

      await _firestore.collection('registrations').doc(registrationId).set(record);
      await EventService().incrementRegistered(eventId);
      return true;
    } catch (e) {
      debugPrint('registerEvent error: $e');
      return false;
    }
  }

  Future<bool> cancelRegistration(String registrationId) async {
    try {
      final doc = await _firestore.collection('registrations').doc(registrationId).get();
      if (!doc.exists) {
        return false;
      }
      final data = doc.data() ?? {};
      final eventId = (data['eventId'] ?? '') as String;
      final prevStatus = (data['status'] ?? 'confirmed') as String;

      await _firestore.collection('registrations').doc(registrationId).update({'status': 'cancelled'});

      if (eventId.isNotEmpty && prevStatus != 'cancelled') {
        await EventService().decrementRegistered(eventId);
      }
      return true;
    } catch (e) {
      debugPrint('cancelRegistration error: $e');
      return false;
    }
  }

  Future<List<Registration>> getUserRegistrations(String userId) async {
    try {
      final qs = await _firestore
          .collection('registrations')
          .where('userId', isEqualTo: userId)
          .get();
      final List<Registration> list = [];
      for (final doc in qs.docs) {
        final m = Map<String, dynamic>.from(doc.data());
        final ts = m['registeredAt'];
        if (ts is Timestamp) {
          m['registeredAt'] = ts.toDate().toIso8601String();
        }
        final reg = Registration.fromJson(m);
        if (reg.status != 'cancelled') {
          list.add(reg);
        }
      }
      return list;
    } catch (e) {
      debugPrint('getUserRegistrations error: $e');
      return [];
    }
  }

  Future<bool> isUserRegistered(String userId, String eventId) async {
    try {
      final qs = await _firestore
          .collection('registrations')
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .get();
      for (final doc in qs.docs) {
        final data = doc.data();
        final status = (data['status'] ?? 'confirmed') as String;
        if (status != 'cancelled') return true;
      }
      return false;
    } catch (e) {
      debugPrint('isUserRegistered error: $e');
      return false;
    }
  }

  Future<Registration?> getRegistration(String userId, String eventId) async {
    try {
      final qs = await _firestore
          .collection('registrations')
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();
      if (qs.docs.isEmpty) return null;
      final m = Map<String, dynamic>.from(qs.docs.first.data());
      final ts = m['registeredAt'];
      if (ts is Timestamp) {
        m['registeredAt'] = ts.toDate().toIso8601String();
      }
      return Registration.fromJson(m);
    } catch (e) {
      debugPrint('getRegistration error: $e');
      return null;
    }
  }
}