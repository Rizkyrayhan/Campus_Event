class AppConstants {
  static const String appName = 'CampusEvent';
  static const String appVersion = '1.0.0';

  // SharedPreferences Keys
  static const String isLoggedInKey = 'is_logged_in';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userNameKey = 'user_name';
  static const String userPhoneKey = 'user_phone';
  static const String userFacultyKey = 'user_faculty';
  static const String userNimKey = 'user_nim';
  static const String favoriteEventsKey = 'favorite_events';

  // Categories
  static const List<String> eventCategories = [
    'Semua',
    'Seminar',
    'Workshop',
    'Kompetisi',
    'Networking',
  ];

  // Faculty
  static const List<String> faculties = [
    'Teknik Informatika',
    'Teknik Elektro',
    'Teknik Mesin',
    'Teknik Sipil',
    'Ilmu Komputer',
    'Sistem Informasi',
  ];
}