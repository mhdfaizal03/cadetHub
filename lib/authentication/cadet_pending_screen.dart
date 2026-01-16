import 'package:flutter/material.dart';
import 'package:ncc_cadet/authentication/login_page.dart';
import 'package:ncc_cadet/services/auth_service.dart';

class CadetPendingPage extends StatelessWidget {
  const CadetPendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, size: 70, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              "Approval Pending",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your registration is under officer review",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                await AuthService().logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginPage(initialRole: 'cadet'),
                    ),
                    (route) => false,
                  );
                }
              },
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
