import 'package:flutter/material.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.getInstance();
  runApp(PopcornBattleApp(isLoggedIn: storage.isLoggedIn));
}

class PopcornBattleApp extends StatelessWidget {
  final bool isLoggedIn;

  const PopcornBattleApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Popcorn Battle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
