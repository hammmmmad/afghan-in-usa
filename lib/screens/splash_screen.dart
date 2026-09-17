import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../utils/constants.dart';
import 'main_shell.dart';

/// Full-screen Lottie intro, then a fade into the app shell.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) _goHome();
    });
    // Safety net: never trap the user on the splash screen.
    Future<void>.delayed(const Duration(seconds: 5), _goHome);
  }

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder:
            (_, Animation<double> animation, __, Widget child) =>
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
      backgroundColor: AppColors.primaryDark,
      body: SizedBox.expand(
        child: Lottie.asset(
          AppAssets.splash,
          controller: _controller,
          fit: BoxFit.cover,
          onLoaded: (LottieComposition composition) {
            _controller
              ..duration = composition.duration
              ..forward();
          },
          errorBuilder: (_, __, ___) {
            // If the animation cannot be decoded, show the logo and move on.
            Future<void>.delayed(const Duration(milliseconds: 900), _goHome);
            return Center(
              child: Image.asset(AppAssets.logo, width: 160),
            );
          },
        ),
      ),
    );
  }
}
