import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ncc_cadet/authentication/login_page.dart';
import 'package:ncc_cadet/utils/theme.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.authBackground,
      body: Stack(
        children: [
          // Background Gradient decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.navyBlue.withOpacity(0.05),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 50,
                    color: AppTheme.navyBlue.withOpacity(0.05),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.orange.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 40,
                    color: AppTheme.orange.withOpacity(0.1),
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),

                  // Logo/Header Area
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.navyBlue.withOpacity(0.05),
                        border: Border.all(color: AppTheme.orange, width: 2),
                      ),
                      child: Image.asset(
                        'assets/cadetHubapplogo.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ).animate().scale(
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  ),

                  const SizedBox(height: 32),

                  Text(
                    "Welcome to CadetHub",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.navyBlue,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ).animate().fade().slideY(begin: 0.3, end: 0, delay: 200.ms),

                  const SizedBox(height: 12),

                  Text(
                    "Please select your role to continue",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ).animate().fade(delay: 400.ms),

                  const Spacer(flex: 2),

                  // Cadet Card
                  _RoleCard(
                    title: "I am a Cadet",
                    subtitle: "Access training, schedule & profile",
                    icon: Icons.person_outline,
                    color: AppTheme.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginPage(initialRole: 'cadet'),
                      ),
                    ),
                  ).animate().slideX(
                    begin: -1,
                    end: 0,
                    delay: 600.ms,
                    duration: 500.ms,
                  ),

                  const SizedBox(height: 20),

                  // Officer Card
                  _RoleCard(
                    title: "I am an Officer",
                    subtitle: "Manage units, approve cadets & more",
                    icon: Icons.local_police_outlined,
                    color: AppTheme.navyBlue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginPage(initialRole: 'officer'),
                      ),
                    ),
                  ).animate().slideX(
                    begin: 1,
                    end: 0,
                    delay: 800.ms,
                    duration: 500.ms,
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            borderRadius: BorderRadius.circular(20),
            color: color.withOpacity(0.1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.navyBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
