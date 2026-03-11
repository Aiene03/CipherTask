import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/key_storage_service.dart';
import 'services/encryption_service.dart';
import 'services/database_service.dart';
import 'services/session_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/todo_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'views/login_view.dart';
import 'views/profile_view.dart';
import 'views/todo_list_view.dart';
import 'views/splash_view.dart';
import 'utils/constants.dart';
import 'utils/transitions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  try {
    await FlutterWindowManagerPlus.addFlags(
      FlutterWindowManagerPlus.FLAG_SECURE,
    );
  } catch (e) {
    debugPrint('WindowManager not supported on this platform');
  }

  final keyStorage = KeyStorageService();
  final dbKey = await keyStorage.getOrCreateDatabaseKey(
    AppConstants.dbKeyStorageKey,
  );

  final encryptionService = EncryptionService(dbKey);
  final databaseService = DatabaseService(dbKey);
  final sessionService = SessionService(AppConstants.sessionTimeoutMinutes);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(keyStorage, sessionService),
        ),
        ChangeNotifierProvider(
          create: (_) => TodoViewModel(databaseService, encryptionService),
        ),
        ChangeNotifierProvider(create: (_) => ThemeViewModel(keyStorage)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthViewModel, ThemeViewModel>(
      builder: (context, authViewModel, themeViewModel, _) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => authViewModel.handleUserInteraction(),
          child: MaterialApp(
            title: 'CipherTask',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0E62DD),
                brightness: Brightness.light,
                primary: const Color(0xFF0E62DD),
                onPrimary: Colors.white,
                secondary: const Color(0xFF26A69A),
                onSecondary: Colors.white,
                background: const Color(0xFFF8FAFC),
                surface: Colors.white,
                onSurface: const Color(0xFF1E293B),
                outline: const Color(0xFFCBD5E1),
              ),
              brightness: Brightness.light,
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF7FAFF),
              primaryColor: const Color(0xFF0E62DD),
              cardColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF0F172A),
                elevation: 0,
                titleTextStyle: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
                iconTheme: IconThemeData(color: Color(0xFF0F172A)),
              ),
              textTheme: ThemeData.light().textTheme.copyWith(
                headlineSmall: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                titleMedium: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w600,
                ),
                bodyLarge: const TextStyle(color: Color(0xFF1E293B)),
                bodyMedium: const TextStyle(color: Color(0xFF334155)),
                labelLarge: const TextStyle(color: Color(0xFF1E293B)),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color.fromRGBO(255, 255, 255, 0.95),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF0E62DD),
                    width: 1.8,
                  ),
                ),
                labelStyle: const TextStyle(color: Color(0xFF475569)),
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E62DD),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 1,
                  shadowColor: const Color(0x660E62DD),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Color(0xFF0E62DD),
                foregroundColor: Colors.white,
                elevation: 4,
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 1,
                shadowColor: const Color(0x1A0E62DD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              brightness: Brightness.dark,
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF0F172A),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF071428),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              cardColor: const Color(0xFF1E293B),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color.fromRGBO(255, 255, 255, 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.cyanAccent,
                    width: 1.5,
                  ),
                ),
                labelStyle: const TextStyle(color: Colors.white70),
                hintStyle: const TextStyle(color: Colors.white54),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            themeMode: themeViewModel.themeMode,
            debugShowCheckedModeBanner: false,
            home: const SplashView(),
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/splash':
                  return FadePageTransition(child: const SplashView());
                case '/login':
                  return FadePageTransition(child: const LoginView());
                case '/todos':
                  return FadePageTransition(child: const TodoListView());
                case '/profile':
                  return FadePageTransition(child: const ProfileView());
                default:
                  return FadePageTransition(child: const SplashView());
              }
            },
          ),
        );
      },
    );
  }
}
