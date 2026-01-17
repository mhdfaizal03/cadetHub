import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:ncc_cadet/authentication/cadet_pending_screen.dart';
import 'package:ncc_cadet/authentication/login_page.dart';
import 'package:ncc_cadet/authentication/welcome_page.dart';

import 'package:ncc_cadet/providers/user_provider.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/role_navigation.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:ncc_cadet/services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      // Artificial delay for splash animation
      await Future.delayed(const Duration(seconds: 2));

      // Request Notification Permission on Startup
      // We await this to ensure the user sees the prompt before navigating
      try {
        await NotificationService().requestPermission();
      } catch (e) {
        debugPrint("Splash: Error requesting permission: $e");
      }

      if (!mounted) return;

      final authService = AuthService();
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Check if user is logged in
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        // Fetch user data
        try {
          final userModel = await authService.getUserProfile();

          if (mounted) {
            if (userModel != null) {
              userProvider.setUser(userModel);

              // Route based on role and status
              if (userModel.role == 'cadet') {
                if (userModel.status == 0) {
                  _navigate(const CadetPendingPage());
                } else if (userModel.status == -1) {
                  await authService.logout();
                  if (mounted) _showError("Your registration was rejected.");
                  _navigate(const LoginPage());
                } else {
                  // Approved
                  navigateByRole(context, 'cadet');
                }
              } else {
                // Officer or other roles
                navigateByRole(context, userModel.role);
              }
            } else {
              // User exists in Auth but not in Firestore (rare edge case)
              await authService.logout();
              _navigate(const WelcomePage());
            }
          }
        } catch (e) {
          debugPrint("Splash: Error fetching user profile: $e");
          // If error fetching profile, safely go to login/welcome
          _navigate(const WelcomePage());
        }
      } else {
        _navigate(const WelcomePage());
      }
    } catch (e) {
      debugPrint("Splash: Fatal Error in _checkAuth: $e");
      // Fallback navigation
      if (mounted) _navigate(const WelcomePage());
    }
  }

  void _navigate(Widget page) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.authBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.navyBlue.withOpacity(0.05),
                border: Border.all(color: AppTheme.orange, width: 2),
              ),
              child: Image.asset(
                'assets/cadetHublogo.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ).animate().fade(duration: 600.ms).scale(delay: 200.ms),

            const SizedBox(height: 24),

            Text(
              'CADETHUB',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: AppTheme.navyBlue,
              ),
            ).animate().fade(delay: 400.ms).slideY(begin: 0.3, end: 0),

            const SizedBox(height: 8),

            Text(
              'National Cadet Corps Management',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ).animate().fade(delay: 600.ms),

            const SizedBox(height: 48),

            const CircularProgressIndicator(
              color: AppTheme.orange,
            ).animate().fade(delay: 800.ms),
          ],
        ),
      ),
    );
  }
}
