import 'dart:async';
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
  StreamSubscription<List<Event>>? _eventsSub;

  List<Event> get events => _filteredEvents;
  List<Event> get allEvents => _allEvents;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  EventProvider() {
    _subscribeEvents();
  }

  void _subscribeEvents() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _eventsSub?.cancel();
    _eventsSub = _eventService.streamAllEvents().listen(
      (events) {
        _allEvents = events;
        _filterEvents();
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Gagal memuat event: ${e.toString()}';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allEvents = await _eventService.getAllEvents();
      _filterEvents();
    } catch (e) {
      _errorMessage = 'Gagal memuat event: ${e.toString()}';
      _allEvents = [];
      _filteredEvents = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }

  Future<void> filterByCategory(String category) async {
    _selectedCategory = category;
    // Tidak perlu panggil service lagi, cukup filter dari data yang ada
    _filterEvents();
    notifyListeners();
  }

  // Fungsi internal untuk melakukan filter
  void _filterEvents() {
    if (_selectedCategory == 'Semua') {
      _filteredEvents = List.from(_allEvents);
    } else {
      _filteredEvents =
          _allEvents.where((e) => e.category == _selectedCategory).toList();
    }
  }

  Future<void> searchEvents(String query) async {
    if (query.isEmpty) {
      _filterEvents();
      notifyListeners();
      return;
    }

    final lowerQuery = query.toLowerCase();
    _filteredEvents = _allEvents
        .where((event) =>
            event.title.toLowerCase().contains(lowerQuery) ||
            event.description.toLowerCase().contains(lowerQuery))
        .toList();
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