import 'package:flutter/material.dart';
import '../models/registration_model.dart';
import '../services/registration_service.dart';
import '../services/event_service.dart';

class RegistrationProvider extends ChangeNotifier {
  final RegistrationService _registrationService = RegistrationService();
  final EventService _eventService = EventService();
  List<Registration> _userRegistrations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Registration> get registrations => _userRegistrations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadUserRegistrations(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _userRegistrations =
          await _registrationService.getUserRegistrations(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat pendaftaran: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> registerEvent(String userId, String eventId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success =
          await _registrationService.registerEvent(userId, eventId);
      if (success) {
        final incOk = await _eventService.incrementRegistered(eventId);
        if (!incOk) {
          debugPrint('❌ Gagal increment registered untuk event: $eventId');
        } else {
          debugPrint('✅ Registered incremented untuk event: $eventId');
        }
        await loadUserRegistrations(userId);
        _errorMessage = null;
      } else {
        _errorMessage = 'Anda sudah terdaftar di event ini';
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Gagal mendaftar: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelRegistration(String registrationId, String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _registrationService.cancelRegistration(registrationId);
      if (success) {
        final idx = _userRegistrations.indexWhere((r) => r.id == registrationId);
        String? eventId;
        if (idx != -1) {
          eventId = _userRegistrations[idx].eventId;
        }
        if (eventId != null) {
          final decOk = await _eventService.decrementRegistered(eventId);
          if (!decOk) {
            debugPrint('❌ Gagal decrement registered untuk event: $eventId');
          } else {
            debugPrint('✅ Registered decremented untuk event: $eventId');
          }
        }
        _userRegistrations.removeWhere((r) => r.id == registrationId);
        _errorMessage = null;
      } else {
        _errorMessage = 'Gagal membatalkan pendaftaran';
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Gagal membatalkan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> isUserRegistered(String userId, String eventId) async {
    return await _registrationService.isUserRegistered(userId, eventId);
  }

  Future<List<Registration>> getUserRegistrations(String userId) async {
    return await _registrationService.getUserRegistrations(userId);
  }
}