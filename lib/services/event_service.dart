import '../models/event_model.dart';

class EventService {
  static final EventService _instance = EventService._internal();

  factory EventService() {
    return _instance;
  }

  EventService._internal();

  final List<Event> _events = [
    Event(
      id: '1',
      title: 'Workshop Flutter Advanced',
      description: 'Pelajari teknik advanced dalam Flutter development termasuk state management dengan Provider, BLoC pattern, animation, dan performance optimization.',
      category: 'Workshop',
      dateTime: DateTime.now().add(const Duration(days: 3)),
      location: 'Gedung A, Ruang 101',
      organizer: 'Tim Development',
      imageUrl: 'https://via.placeholder.com/400x250?text=Flutter+Workshop',
      capacity: 50,
      registered: 42,
      speaker: 'Ahmad Rizki',
      contact: '081234567890',
      isFavorite: false,
      createdAt: DateTime.now(),
    ),
    Event(
      id: '2',
      title: 'Seminar AI & Machine Learning',
      description: 'Pembicara industri berbagi pengalaman tentang implementasi AI dan ML dalam dunia nyata.',
      category: 'Seminar',
      dateTime: DateTime.now().add(const Duration(days: 5)),
      location: 'Aula Utama',
      organizer: 'Fakultas Teknologi',
      imageUrl: 'https://via.placeholder.com/400x250?text=AI+Seminar',
      capacity: 200,
      registered: 156,
      speaker: 'Dr. Budi Santoso',
      contact: '082345678901',
      isFavorite: false,
      createdAt: DateTime.now(),
    ),
    Event(
      id: '3',
      title: 'Hackathon Campus 2024',
      description: 'Kompetisi coding 24 jam untuk mahasiswa dengan hadiah menarik dan kesempatan magang di perusahaan teknologi terkemuka.',
      category: 'Kompetisi',
      dateTime: DateTime.now().add(const Duration(days: 10)),
      location: 'Lab Komputer',
      organizer: 'Student Developer Community',
      imageUrl: 'https://via.placeholder.com/400x250?text=Hackathon',
      capacity: 100,
      registered: 87,
      speaker: 'Tim Organizer',
      contact: '083456789012',
      isFavorite: false,
      createdAt: DateTime.now(),
    ),
    Event(
      id: '4',
      title: 'Networking Profesional IT',
      description: 'Bertemu dengan profesional dari perusahaan teknologi terkemuka untuk berbagi karir dan peluang kerja.',
      category: 'Networking',
      dateTime: DateTime.now().add(const Duration(days: 7)),
      location: 'Gedung B, Hall 2',
      organizer: 'Career Center',
      imageUrl: 'https://via.placeholder.com/400x250?text=Networking',
      capacity: 80,
      registered: 65,
      speaker: 'HR Professionals',
      contact: '084567890123',
      isFavorite: false,
      createdAt: DateTime.now(),
    ),
    Event(
      id: '5',
      title: 'Web Development Bootcamp',
      description: 'Bootcamp intensif 2 minggu untuk belajar web development modern dengan teknologi terbaru.',
      category: 'Workshop',
      dateTime: DateTime.now().add(const Duration(days: 14)),
      location: 'Gedung C, Ruang 205',
      organizer: 'Coding School',
      imageUrl: 'https://via.placeholder.com/400x250?text=Web+Bootcamp',
      capacity: 30,
      registered: 28,
      speaker: 'Muhammad Fauzi',
      contact: '085678901234',
      isFavorite: false,
      createdAt: DateTime.now(),
    ),
  ];

  Future<List<Event>> getAllEvents() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _events;
  }

  Future<Event?> getEventById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _events.firstWhere((event) => event.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Event>> getEventsByCategory(String category) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (category == 'Semua') return _events;
    return _events.where((event) => event.category == category).toList();
  }

  Future<List<Event>> searchEvents(String query) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final lowerQuery = query.toLowerCase();
    return _events
        .where((event) =>
            event.title.toLowerCase().contains(lowerQuery) ||
            event.description.toLowerCase().contains(lowerQuery) ||
            event.location.toLowerCase().contains(lowerQuery))
        .toList();
  }

  void updateFavoriteStatus(String eventId, bool isFavorite) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      _events[index] = _events[index].copyWith(isFavorite: isFavorite);
    }
  }

  Future<List<Event>> getFavoriteEvents() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _events.where((event) => event.isFavorite).toList();
  }
}
