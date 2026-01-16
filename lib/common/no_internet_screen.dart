import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ncc_cadet/utils/theme.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 64,
                  color: Colors.red,
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 32),
              const Text(
                "No Internet Connection",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navyBlue,
                ),
                textAlign: TextAlign.center,
              ).animate().fade().slideY(begin: 0.2, end: 0, delay: 200.ms),
              const SizedBox(height: 16),
              Text(
                "Please check your internet settings and try again.",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ).animate().fade(delay: 400.ms),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () =>
                      AppSettings.openAppSettings(type: AppSettingsType.wifi),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.navyBlue,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Open Settings",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ).animate().fade(delay: 600.ms).slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
