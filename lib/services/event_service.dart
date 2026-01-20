import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/event_model.dart';

class EventService {
  static const String _databaseUrl =
      'https://campus-event-df7db-default-rtdb.asia-southeast1.firebasedatabase.app';

  static final EventService _instance = EventService._internal();

  factory EventService() {
    return _instance;
  }

  late final FirebaseDatabase _db;
  late final DatabaseReference _eventsRef;


  EventService._internal() {
    final FirebaseApp app = Firebase.app();
    final String dbUrl = app.options.databaseURL ?? _databaseUrl;
    _db = FirebaseDatabase.instanceFor(app: app, databaseURL: dbUrl);
    _eventsRef = _db.ref('events');
    

  }

  Future<List<Event>> getAllEvents() async {
    try {
      debugPrint('Fetching events from Firebase Realtime Database...');
      debugPrint('Database URL: $_databaseUrl');
      debugPrint('Path: ${_eventsRef.path}');

      final snapshot = await _eventsRef.get();

      debugPrint('Snapshot exists: ${snapshot.exists}');
      debugPrint('Snapshot has children: ${snapshot.children.isNotEmpty}');

      if (snapshot.exists && snapshot.value != null) {
        final dynamic value = snapshot.value;
        final List<Event> loadedEvents = [];

        debugPrint('Data type: ${value.runtimeType}');

        if (value is Map) {
          debugPrint(
              'Processing Map/Object data with ${(value as Map).length} items');
          value.forEach((key, val) {
            try {
              debugPrint('Processing key: $key');
              if (val is Map) {
                final eventData = Map<String, dynamic>.from(val);
                eventData['id'] = key.toString();
                _addDefaultFieldsExtended(eventData);

                final event = Event.fromJson(eventData);
                loadedEvents.add(event);
                debugPrint('Event loaded: ${event.title}');
              }
            } catch (e) {
              debugPrint('Error processing item $key: $e');
            }
          });
        } else if (value is List) {
          debugPrint(
              'Processing List/Array data with ${(value as List).length} items');
          for (var i = 0; i < value.length; i++) {
            try {
              if (value[i] != null && value[i] is Map) {
                final eventData = Map<String, dynamic>.from(value[i] as Map);
                if (eventData['id'] == null ||
                    (eventData['id'] is String &&
                        (eventData['id'] as String).isEmpty)) {
                  eventData['id'] = i.toString();
                }
                _addDefaultFieldsExtended(eventData);

                final event = Event.fromJson(eventData);
                loadedEvents.add(event);
                debugPrint('Event loaded: ${event.title}');
              }
            } catch (e) {
              debugPrint('Error processing item $i: $e');
            }
          }
        }

        debugPrint('Total events loaded: ${loadedEvents.length}');
        return loadedEvents;
      } else {
        debugPrint('No data found in Firebase');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting events: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Stream<List<Event>> streamAllEvents() {
    debugPrint('🔌 Starting stream subscription for events...');

    return _eventsRef.onValue.map((event) {
      final snapshot = event.snapshot;
      final value = snapshot.value;

      debugPrint('Stream received data');

      if (value == null) {
        debugPrint('Stream received null data');
        return <Event>[];
      }

      final List<Event> loadedEvents = [];

      if (value is Map) {
        debugPrint('Stream: Processing Map with ${(value as Map).length} items');
        value.forEach((key, val) {
          try {
            if (val is Map) {
              final eventData = Map<String, dynamic>.from(val);
              eventData['id'] = key.toString();
              _addDefaultFieldsExtended(eventData);
              loadedEvents.add(Event.fromJson(eventData));
            }
          } catch (e) {
            debugPrint('Stream error processing $key: $e');
          }
        });
      } else if (value is List) {
        debugPrint('Stream: Processing List with ${(value as List).length} items');
        for (var i = 0; i < value.length; i++) {
          try {
            if (value[i] != null && value[i] is Map) {
              final eventData = Map<String, dynamic>.from(value[i] as Map);
              if (eventData['id'] == null ||
                  (eventData['id'] is String &&
                      (eventData['id'] as String).isEmpty)) {
                eventData['id'] = i.toString();
              }
              _addDefaultFieldsExtended(eventData);
              loadedEvents.add(Event.fromJson(eventData));
            }
          } catch (e) {
            debugPrint('Stream error processing item $i: $e');
          }
        }
      }

      debugPrint('Stream returned ${loadedEvents.length} events');
      return loadedEvents;
    });
  }

  Future<Event?> getEventById(String id) async {
    try {
      debugPrint('Fetching event by id: $id');
      final snapshot = await _eventsRef.child(id).get();

      if (snapshot.exists && snapshot.value != null) {
        final eventData = Map<String, dynamic>.from(snapshot.value as Map);
        eventData['id'] = id;
        _addDefaultFieldsExtended(eventData);
        final event = Event.fromJson(eventData);
        debugPrint('Event found: ${event.title}');
        return event;
      }

      debugPrint('Event not found: $id');
      return null;
    } catch (e) {
      debugPrint('Error getting event by id: $e');
      return null;
    }
  }

  Future<List<Event>> getEventsByCategory(String category) async {
    final allEvents = await getAllEvents();
    if (category == 'Semua') return allEvents;
    return allEvents.where((event) => event.category == category).toList();
  }

  Future<List<Event>> searchEvents(String query) async {
    final allEvents = await getAllEvents();
    final lowerQuery = query.toLowerCase();
    return allEvents
        .where(
          (event) =>
              event.title.toLowerCase().contains(lowerQuery) ||
              event.description.toLowerCase().contains(lowerQuery) ||
              event.location.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  Future<void> updateFavoriteStatus(String eventId, bool isFavorite) async {
    try {
      await _eventsRef.child(eventId).update({'isFavorite': isFavorite});
      debugPrint('Favorite status updated for: $eventId');
    } catch (e) {
      debugPrint('Error updating favorite: $e');
    }
  }

  Future<bool> incrementRegistered(String eventId) async {
    try {
      final ref = _eventsRef.child(eventId).child('registered');
      final snap = await ref.get();
      int current = 0;
      if (snap.exists && snap.value is int) {
        current = snap.value as int;
      }
      final next = current + 1;
      await ref.set(next);
      debugPrint('Registered +1 untuk event: $eventId (baru: $next)');
      return true;
    } catch (e) {
      debugPrint('Error increment registered untuk $eventId: $e');
      return false;
    }
  }

  Future<bool> decrementRegistered(String eventId) async {
    try {
      final ref = _eventsRef.child(eventId).child('registered');
      final snap = await ref.get();
      int current = 0;
      if (snap.exists && snap.value is int) {
        current = snap.value as int;
      }
      final next = current > 0 ? current - 1 : 0;
      await ref.set(next);
      debugPrint('Registered -1 untuk event: $eventId (baru: $next)');
      return true;
    } catch (e) {
      debugPrint('Error decrement registered untuk $eventId: $e');
      return false;
    }
  }

  Future<List<Event>> getFavoriteEvents() async {
    final allEvents = await getAllEvents();
    return allEvents.where((event) => event.isFavorite).toList();
  }

  void _addDefaultFieldsExtended(Map<String, dynamic> eventData) {
    // Konversi date dan time ke dateTime jika perlu
    if (!eventData.containsKey('dateTime')) {
      if (eventData.containsKey('date') && eventData.containsKey('time')) {
        final date = eventData['date'] as String;
        final time = eventData['time'] as String;
        eventData['dateTime'] = '${date}T${time}:00.000Z';
      } else {
        eventData['dateTime'] = DateTime.now().toIso8601String();
      }
    }

    // Field wajib dengan nilai default
    eventData['category'] ??= 'General';
    eventData['organizer'] ??= 'Unknown Organizer';
    eventData['capacity'] ??= 100;
    eventData['registered'] ??= 0;
    eventData['speaker'] ??= 'TBA';
    eventData['contact'] ??= 'No Contact';
    eventData['isFavorite'] ??= false;
    eventData['createdAt'] ??= DateTime.now().toIso8601String();
    eventData['imageUrl'] ??= 'https://via.placeholder.com/300x200?text=No+Image';
    eventData['title'] ??= 'Untitled Event';
    eventData['description'] ??= 'No description available';
    eventData['location'] ??= 'Location TBA';
  }



  // Helper untuk debug
  Future<void> debugPrintDatabase() async {
    try {
      debugPrint('\n========== DATABASE DEBUG INFO ==========');
      final snapshot = await _eventsRef.get();
      debugPrint('Exists: ${snapshot.exists}');
      debugPrint('Has children: ${snapshot.children.isNotEmpty}');
      if (snapshot.value != null) {
        debugPrint('Value type: ${snapshot.value.runtimeType}');
        if (snapshot.value is Map) {
          final map = snapshot.value as Map;
          debugPrint('Number of items: ${map.length}');
          map.forEach((key, value) {
            if (value is Map && value.containsKey('title')) {
              debugPrint('  - $key: ${value['title']}');
            }
          });
        }
      }
      debugPrint('==========================================\n');
    } catch (e) {
      debugPrint('Debug error: $e');
    }
  }
}