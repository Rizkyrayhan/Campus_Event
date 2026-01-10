class Registration {
  final String id;
  final String userId;
  final String eventId;
  final DateTime registeredAt;
  final String status; // 'pending', 'confirmed', 'cancelled'
  final bool isAttended;

  Registration({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.registeredAt,
    this.status = 'pending',
    this.isAttended = false,
  });

  Registration copyWith({
    String? id,
    String? userId,
    String? eventId,
    DateTime? registeredAt,
    String? status,
    bool? isAttended,
  }) {
    return Registration(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      registeredAt: registeredAt ?? this.registeredAt,
      status: status ?? this.status,
      isAttended: isAttended ?? this.isAttended,
    );
  }

  factory Registration.fromJson(Map<String, dynamic> json) {
    return Registration(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      eventId: json['eventId'] ?? '',
      registeredAt: DateTime.parse(json['registeredAt'] ?? DateTime.now().toString()),
      status: json['status'] ?? 'pending',
      isAttended: json['isAttended'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'eventId': eventId,
      'registeredAt': registeredAt.toIso8601String(),
      'status': status,
      'isAttended': isAttended,
    };
  }
}