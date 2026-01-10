class Event {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime dateTime;
  final String location;
  final String organizer;
  final String imageUrl;
  final int capacity;
  final int registered;
  final String speaker;
  final String contact;
  final bool isFavorite;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.dateTime,
    required this.location,
    required this.organizer,
    required this.imageUrl,
    required this.capacity,
    required this.registered,
    required this.speaker,
    required this.contact,
    this.isFavorite = false,
    required this.createdAt,
  });

  bool get isFull => registered >= capacity;
  double get capacityPercentage => registered / capacity;
  bool get hasAvailableSlot => registered < capacity;

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? dateTime,
    String? location,
    String? organizer,
    String? imageUrl,
    int? capacity,
    int? registered,
    String? speaker,
    String? contact,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      organizer: organizer ?? this.organizer,
      imageUrl: imageUrl ?? this.imageUrl,
      capacity: capacity ?? this.capacity,
      registered: registered ?? this.registered,
      speaker: speaker ?? this.speaker,
      contact: contact ?? this.contact,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      dateTime: DateTime.parse(json['dateTime'] ?? DateTime.now().toString()),
      location: json['location'] ?? '',
      organizer: json['organizer'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      capacity: json['capacity'] ?? 0,
      registered: json['registered'] ?? 0,
      speaker: json['speaker'] ?? '',
      contact: json['contact'] ?? '',
      isFavorite: json['isFavorite'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'organizer': organizer,
      'imageUrl': imageUrl,
      'capacity': capacity,
      'registered': registered,
      'speaker': speaker,
      'contact': contact,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}