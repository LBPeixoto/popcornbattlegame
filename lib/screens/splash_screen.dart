import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';
import '../core/theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );

    _fadeOut = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
    );

    _controller.forward().then((_) => _navigate());
  }

  Future<void> _navigate() async {
    final storage = await StorageService.getInstance();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            storage.isLoggedIn ? const HomeScreen() : const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, child) {
            final opacity = (_fadeIn.value - _fadeOut.value).clamp(0.0, 1.0);
            return Opacity(opacity: opacity, child: child);
          },
          child: const _LogoContent(),
        ),
      ),
    );
  }
}

class _LogoContent extends StatelessWidget {
  const _LogoContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Logo(),
        const SizedBox(height: 24),
        const Text(
          'UnGames',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Apresenta',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const assetPath = 'assets/images/ungames_logo.png';
    return Image.asset(
      assetPath,
      width: 140,
      height: 140,
      errorBuilder: (context, error, stackTrace) => Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: const Icon(Icons.videogame_asset, size: 64, color: AppColors.primary),
      ),
    );
  }
}
