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
  bool _hasSeededData = false;

  EventService._internal() {
    final FirebaseApp app = Firebase.app();
    final String dbUrl = app.options.databaseURL ?? _databaseUrl;
    _db = FirebaseDatabase.instanceFor(app: app, databaseURL: dbUrl);
    _eventsRef = _db.ref('events');
    
    // Seed data jika database kosong
    _initializeDataIfNeeded();
  }

  /// Initialize database dengan data default jika kosong
  Future<void> _initializeDataIfNeeded() async {
    if (_hasSeededData) return;

    try {
      debugPrint('🔍 Checking if database has data...');
      final snapshot = await _eventsRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        debugPrint('📝 Database kosong, seeding data...');
        await _seedInitialData();
        _hasSeededData = true;
        debugPrint('✅ Data seeding completed');
      } else {
        debugPrint('✅ Database sudah punya data');
        _hasSeededData = true;
      }
    } catch (e) {
      debugPrint('⚠️ Error checking database: $e');
    }
  }

  /// Seed database dengan data awal
  Future<void> _seedInitialData() async {
    try {
      final List<Map<String, dynamic>> dummyEventsData = [
        {
          'id': 'event1',
          'title': 'Workshop Flutter Dasar',
          'description':
              'Workshop intensif belajar Flutter dari nol. Cocok untuk pemula yang ingin memulai mobile development. Materi mencakup widget basics, state management, dan networking.',
          'category': 'Workshop',
          'dateTime': '2024-02-15T14:00:00.000Z',
          'location': 'Lab Komputer Lantai 2, Gedung A',
          'organizer': 'Tim Development',
          'imageUrl':
              'https://via.placeholder.com/300x200?text=Workshop+Flutter',
          'capacity': 50,
          'registered': 35,
          'speaker': 'Andi Wijaya',
          'contact': '085123456789',
          'isFavorite': false,
          'createdAt': '2024-01-15T08:00:00.000Z',
        },
        {
          'id': 'event2',
          'title': 'Seminar Cloud Computing & AWS',
          'description':
              'Seminar mendalam tentang cloud computing dan praktik penggunaan AWS. Pembicara adalah expert dari industry tech besar dengan pengalaman 10+ tahun.',
          'category': 'Seminar',
          'dateTime': '2024-02-20T10:00:00.000Z',
          'location': 'Auditorium Utama',
          'organizer': 'Tech Community',
          'imageUrl':
              'https://via.placeholder.com/300x200?text=Cloud+Computing',
          'capacity': 200,
          'registered': 150,
          'speaker': 'Dr. Budi Hartono',
          'contact': '087654321098',
          'isFavorite': false,
          'createdAt': '2024-01-10T08:00:00.000Z',
        },
        {
          'id': 'event3',
          'title': 'Kompetisi UI/UX Design',
          'description':
              'Kompetisi desain untuk menampilkan kreativitas Anda dalam membuat interface yang menarik dan user-friendly. Hadiah total 10 juta rupiah.',
          'category': 'Kompetisi',
          'dateTime': '2024-03-01T08:00:00.000Z',
          'location': 'Creative Hub, Lantai 3',
          'organizer': 'Design Club',
          'imageUrl':
              'https://via.placeholder.com/300x200?text=UI+UX+Design',
          'capacity': 100,
          'registered': 45,
          'speaker': 'Citra Desain',
          'contact': '086111222333',
          'isFavorite': false,
          'createdAt': '2024-01-05T08:00:00.000Z',
        },
        {
          'id': 'event4',
          'title': 'Networking Session IT Leaders',
          'description':
              'Kesempatan networking dengan para pemimpin IT dari perusahaan terkemuka. Sharing pengalaman, job opportunities, dan business collaboration.',
          'category': 'Networking',
          'dateTime': '2024-02-25T17:00:00.000Z',
          'location': 'Executive Room, Hotel Bintang Lima',
          'organizer': 'IT Professionals Association',
          'imageUrl':
              'https://via.placeholder.com/300x200?text=Networking',
          'capacity': 80,
          'registered': 65,
          'speaker': 'Multiple Speakers',
          'contact': '088999888777',
          'isFavorite': false,
          'createdAt': '2024-01-12T08:00:00.000Z',
        },
        {
          'id': 'event5',
          'title': 'Workshop Data Science & Machine Learning',
          'description':
              'Workshop praktis machine learning menggunakan Python dan TensorFlow. Belajar tentang data preprocessing, model training, dan deployment.',
          'category': 'Workshop',
          'dateTime': '2024-03-10T13:00:00.000Z',
          'location': 'Data Lab, Gedung B',
          'organizer': 'Data Science Club',
          'imageUrl':
              'https://via.placeholder.com/300x200?text=Data+Science',
          'capacity': 40,
          'registered': 28,
          'speaker': 'Prof. Eka Prasetya',
          'contact': '085555666777',
          'isFavorite': false,
          'createdAt': '2024-01-08T08:00:00.000Z',
        },
      ];

      // Upload semua event
      for (var eventData in dummyEventsData) {
        try {
          await _eventsRef.child(eventData['id']).set(eventData);
          debugPrint('✅ Event created: ${eventData['title']}');
        } catch (e) {
          debugPrint('❌ Error creating event ${eventData['id']}: $e');
        }
      }

      debugPrint('🎉 All events seeded successfully!');
    } catch (e) {
      debugPrint('❌ Error seeding data: $e');
    }
  }

  Future<List<Event>> getAllEvents() async {
    try {
      debugPrint('🔄 Fetching events from Firebase Realtime Database...');
      debugPrint('📍 Database URL: $_databaseUrl');
      debugPrint('📁 Path: ${_eventsRef.path}');

      final snapshot = await _eventsRef.get();

      debugPrint('✅ Snapshot exists: ${snapshot.exists}');
      debugPrint('📊 Snapshot has children: ${snapshot.children.isNotEmpty}');

      if (snapshot.exists && snapshot.value != null) {
        final dynamic value = snapshot.value;
        final List<Event> loadedEvents = [];

        debugPrint('🔍 Data type: ${value.runtimeType}');

        if (value is Map) {
          debugPrint(
              '📦 Processing Map/Object data with ${(value as Map).length} items');
          value.forEach((key, val) {
            try {
              debugPrint('⚙️ Processing key: $key');
              if (val is Map) {
                final eventData = Map<String, dynamic>.from(val);
                eventData['id'] = key.toString();
                _addDefaultFieldsExtended(eventData);

                final event = Event.fromJson(eventData);
                loadedEvents.add(event);
                debugPrint('✨ Event loaded: ${event.title}');
              }
            } catch (e) {
              debugPrint('❌ Error processing item $key: $e');
            }
          });
        } else if (value is List) {
          debugPrint(
              '📦 Processing List/Array data with ${(value as List).length} items');
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
                debugPrint('✨ Event loaded: ${event.title}');
              }
            } catch (e) {
              debugPrint('❌ Error processing item $i: $e');
            }
          }
        }

        debugPrint('🎉 Total events loaded: ${loadedEvents.length}');
        return loadedEvents;
      } else {
        debugPrint('⚠️ No data found in Firebase');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting events: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  Stream<List<Event>> streamAllEvents() {
    debugPrint('🔌 Starting stream subscription for events...');

    return _eventsRef.onValue.map((event) {
      final snapshot = event.snapshot;
      final value = snapshot.value;

      debugPrint('📡 Stream received data');

      if (value == null) {
        debugPrint('⚠️ Stream received null data');
        return <Event>[];
      }

      final List<Event> loadedEvents = [];

      if (value is Map) {
        debugPrint('📦 Stream: Processing Map with ${(value as Map).length} items');
        value.forEach((key, val) {
          try {
            if (val is Map) {
              final eventData = Map<String, dynamic>.from(val);
              eventData['id'] = key.toString();
              _addDefaultFieldsExtended(eventData);
              loadedEvents.add(Event.fromJson(eventData));
            }
          } catch (e) {
            debugPrint('❌ Stream error processing $key: $e');
          }
        });
      } else if (value is List) {
        debugPrint('📦 Stream: Processing List with ${(value as List).length} items');
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
            debugPrint('❌ Stream error processing item $i: $e');
          }
        }
      }

      debugPrint('🎉 Stream returned ${loadedEvents.length} events');
      return loadedEvents;
    });
  }

  Future<Event?> getEventById(String id) async {
    try {
      debugPrint('🔍 Fetching event by id: $id');
      final snapshot = await _eventsRef.child(id).get();

      if (snapshot.exists && snapshot.value != null) {
        final eventData = Map<String, dynamic>.from(snapshot.value as Map);
        eventData['id'] = id;
        _addDefaultFieldsExtended(eventData);
        final event = Event.fromJson(eventData);
        debugPrint('✅ Event found: ${event.title}');
        return event;
      }

      debugPrint('⚠️ Event not found: $id');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting event by id: $e');
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
      debugPrint('✅ Favorite status updated for: $eventId');
    } catch (e) {
      debugPrint('❌ Error updating favorite: $e');
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
      debugPrint('✅ Registered +1 untuk event: $eventId (baru: $next)');
      return true;
    } catch (e) {
      debugPrint('❌ Error increment registered untuk $eventId: $e');
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
      debugPrint('✅ Registered -1 untuk event: $eventId (baru: $next)');
      return true;
    } catch (e) {
      debugPrint('❌ Error decrement registered untuk $eventId: $e');
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

  // Manual reset & reseed
  Future<void> clearAndReseedDatabase() async {
    try {
      debugPrint('🗑️ Clearing all events...');
      await _eventsRef.remove();
      debugPrint('✅ All events cleared');
      
      _hasSeededData = false;
      await _initializeDataIfNeeded();
    } catch (e) {
      debugPrint('❌ Error clearing database: $e');
    }
  }

  // Helper untuk debug
  Future<void> debugPrintDatabase() async {
    try {
      debugPrint('\n========== 📊 DATABASE DEBUG INFO ==========');
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