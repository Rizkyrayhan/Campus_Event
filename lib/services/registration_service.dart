import '../models/registration_model.dart';

class RegistrationService {
  static final RegistrationService _instance = RegistrationService._internal();

  factory RegistrationService() {
    return _instance;
  }

  RegistrationService._internal();

  final List<Registration> _registrations = [];

  Future<bool> registerEvent(String userId, String eventId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      // Cek apakah sudah terdaftar
      final isRegistered = _registrations.any(
        (r) => r.userId == userId && 
               r.eventId == eventId && 
               r.status != 'cancelled',
      );

      if (isRegistered) return false;

      final registration = Registration(
        id: 'reg_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        eventId: eventId,
        registeredAt: DateTime.now(),
        status: 'confirmed',
      );

      _registrations.add(registration);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelRegistration(String registrationId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));

      final index = _registrations.indexWhere((r) => r.id == registrationId);
      if (index != -1) {
        _registrations[index] = _registrations[index].copyWith(status: 'cancelled');
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<Registration>> getUserRegistrations(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _registrations
        .where((r) => r.userId == userId && r.status != 'cancelled')
        .toList();
  }

  Future<bool> isUserRegistered(String userId, String eventId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _registrations.any(
      (r) => r.userId == userId && 
             r.eventId == eventId && 
             r.status != 'cancelled',
    );
  }

  Future<Registration?> getRegistration(String userId, String eventId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _registrations.firstWhere(
        (r) => r.userId == userId && 
               r.eventId == eventId && 
               r.status != 'cancelled',
      );
    } catch (e) {
      return null;
    }
  }
}