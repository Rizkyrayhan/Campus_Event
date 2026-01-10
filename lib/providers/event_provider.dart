import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class EventProvider extends ChangeNotifier {
  final EventService _eventService = EventService();
  List<Event> _allEvents = [];
  List<Event> _filteredEvents = [];
  String _selectedCategory = 'Semua';
  bool _isLoading = false;
  String? _errorMessage;

  List<Event> get events => _filteredEvents;
  List<Event> get allEvents => _allEvents;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  EventProvider() {
    loadEvents();
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allEvents = await _eventService.getAllEvents();
      await filterByCategory('Semua');
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat event: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> filterByCategory(String category) async {
    _selectedCategory = category;
    _isLoading = true;
    notifyListeners();

    try {
      _filteredEvents = await _eventService.getEventsByCategory(category);
    } catch (e) {
      _errorMessage = 'Gagal filter event: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchEvents(String query) async {
    if (query.isEmpty) {
      await filterByCategory(_selectedCategory);
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _filteredEvents = await _eventService.searchEvents(query);
    } catch (e) {
      _errorMessage = 'Gagal mencari event: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void toggleFavorite(String eventId) {
    final index = _allEvents.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      _allEvents[index] = _allEvents[index].copyWith(
        isFavorite: !_allEvents[index].isFavorite,
      );
      _eventService.updateFavoriteStatus(
        eventId,
        _allEvents[index].isFavorite,
      );
      
      // Update filtered events juga
      final filteredIndex = _filteredEvents.indexWhere((e) => e.id == eventId);
      if (filteredIndex != -1) {
        _filteredEvents[filteredIndex] = _allEvents[index];
      }
      
      notifyListeners();
    }
  }

  Future<List<Event>> getFavoriteEvents() async {
    return await _eventService.getFavoriteEvents();
  }

  Event? getEventById(String id) {
    try {
      return _allEvents.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }
}