import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/theme/app_theme.dart';
import 'package:mchs_mobile_app/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    var authState = ref.read(authStateProvider);
    var attempts = 0;
    while (authState.isLoading && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      authState = ref.read(authStateProvider);
      attempts++;
    }

    if (!mounted) return;
    context.go(authState.isAuthenticated ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.10),
                borderRadius: AppRadius.borderRadiusLg,
              ),
              child: Icon(
                Icons.school_outlined,
                size: 32,
                color: context.primaryColor,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'МЧС — обучение',
              style: AppTypography.heading3.copyWith(
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  context.textTertiaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
