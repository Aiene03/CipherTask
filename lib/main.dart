import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';
import 'services/key_storage_service.dart';
import 'services/encryption_service.dart';
import 'services/database_service.dart';
import 'services/session_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/todo_viewmodel.dart';
import 'views/login_view.dart';
import 'views/todo_list_view.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Security Feature: Prevent screenshots and obfuscate in "Recent Apps" (Android)
  try {
    await FlutterWindowManagerPlus.addFlags(FlutterWindowManagerPlus.FLAG_SECURE);
  } catch (e) {
    debugPrint('WindowManager not supported on this platform');
  }

  final keyStorage = KeyStorageService();
  final dbKey = await keyStorage.getOrCreateDatabaseKey(AppConstants.dbKeyStorageKey);
  
  // Initialize services
  final encryptionService = EncryptionService(dbKey);
  final databaseService = DatabaseService(dbKey);
  final sessionService = SessionService(AppConstants.sessionTimeoutMinutes);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(keyStorage, sessionService)),
        // TodoViewModel depends on the services initialized above
        ChangeNotifierProvider(create: (_) => TodoViewModel(databaseService, encryptionService)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => authViewModel.handleUserInteraction(),
          child: MaterialApp(
            title: 'CipherTask',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
              useMaterial3: true,
            ),
            debugShowCheckedModeBanner: false,
            // Logic for auto-lock: If logged out (manually or by timeout), show Login
            home: authViewModel.isLoggedIn ? const TodoListView() : const LoginView(),
            routes: {
              '/login': (context) => const LoginView(),
              '/todos': (context) => const TodoListView(),
            },
          ),
        );
      },
    );
  }
}
