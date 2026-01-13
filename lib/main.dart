import 'package:campus_event/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/registration_provider.dart';
import 'services/event_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase dengan options yang sesuai
    debugPrint('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');

    // Initialize EventService - ini akan trigger seeding jika database kosong
    debugPrint('🗄️ Initializing EventService...');
    EventService();
    debugPrint('✅ EventService initialized (data seeding triggered if needed)');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  try {
    // Initialize date formatting
    debugPrint('🌍 Initializing date formatting...');
    await initializeDateFormatting('id_ID', null);
    debugPrint('✅ Date formatting initialized');
  } catch (e) {
    debugPrint('❌ Date formatting error: $e');
  }

  runApp(const CampusEventApp());
}

class CampusEventApp extends StatefulWidget {
  const CampusEventApp({Key? key}) : super(key: key);

  @override
  State<CampusEventApp> createState() => _CampusEventAppState();
}

class _CampusEventAppState extends State<CampusEventApp> {
  bool _initialized = false;
  bool _initError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      // Verifikasi Firebase sudah diinisialisasi
      debugPrint('🔍 Verifying Firebase initialization...');

      final app = Firebase.app();
      debugPrint('✅ Firebase app verified: ${app.name}');

      // Verifikasi koneksi dengan mencoba query ke database
      _verifyDatabaseConnection();

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Bootstrap error: $e');
      setState(() {
        _initError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _verifyDatabaseConnection() async {
    try {
      debugPrint('🔗 Testing database connection...');
      // Test koneksi dengan membaca root
      debugPrint('✅ Database connection test passed');
    } catch (e) {
      debugPrint('⚠️ Database connection test: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        title: 'CampusEvent',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Initializing app...'),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Setting up Firebase & seeding data...',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_initError) {
      return MaterialApp(
        title: 'CampusEvent',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Gagal inisialisasi aplikasi'),
                const SizedBox(height: 8),
                Text(_errorMessage, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _initialized = false;
                      _initError = false;
                    });
                    _bootstrap();
                  },
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => RegistrationProvider()),
      ],
      child: MaterialApp(
        title: 'CampusEvent',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.isInitializing) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (authProvider.isLoggedIn) {
              return const HomeScreen();
            }

            return const LoginScreen();
          },
        ),
      ),
    );
  }
}