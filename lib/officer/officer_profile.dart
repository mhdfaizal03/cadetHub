import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ncc_cadet/authentication/login_page.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/cadet/nav_bars/cadet_notification_screen.dart'; // Reusing for now
import 'package:ncc_cadet/cadet/profile/edit_profile_screen.dart';
import 'package:ncc_cadet/cadet/profile/help_support_screen.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:ncc_cadet/providers/user_provider.dart';

import 'package:ncc_cadet/common/shimmer_loading.dart';

class OfficerProfileScreen extends StatelessWidget {
  const OfficerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Officer Profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final profile = userProvider.user;

          if (profile == null) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      children: [
                        const ShimmerLoading.circular(height: 100, width: 100),
                        const SizedBox(height: 16),
                        const ShimmerLoading.rectangular(
                          height: 24,
                          width: 150,
                        ),
                        const SizedBox(height: 8),
                        const ShimmerLoading.rectangular(
                          height: 16,
                          width: 100,
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        Row(
                          children: const [
                            Expanded(
                              child: ShimmerLoading.rectangular(height: 60),
                            ),
                            SizedBox(width: 5),
                            Expanded(
                              child: ShimmerLoading.rectangular(height: 60),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const ShimmerLoading.rectangular(height: 60),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const ShimmerLoading.rectangular(height: 60),
                  const SizedBox(height: 15),
                  const ShimmerLoading.rectangular(height: 60),
                  const SizedBox(height: 15),
                  const ShimmerLoading.rectangular(height: 60),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.navyBlue.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.navyBlue,
                        child: CircleAvatar(
                          radius: 47,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.local_police, // Officer Icon
                            size: 50,
                            color: AppTheme.navyBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.navyBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (profile.role == 'officer')
                              ? "Officer"
                              : profile.rank, // Show rank for SUO/UO
                          style: TextStyle(
                            color: AppTheme.navyBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      // Details Grid
                      Row(
                        children: [
                          _buildDetailItem(
                            "Unit Code",
                            profile.organizationId,
                            Icons.verified_user_outlined,
                          ),

                          SizedBox(width: 5),
                          _buildDetailItem(
                            "Status",
                            "Active", // Assuming active if logged in
                            Icons.check_circle_outline,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildDetailItem(
                            "Email",
                            profile.email,
                            Icons.email_outlined,
                            isFullWidth: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Settings & Actions
                _buildActionTile(
                  title: "Edit Profile",
                  icon: Icons.edit_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(user: profile),
                      ),
                    );
                  },
                ),
                _buildActionTile(
                  title: "Notifications",
                  icon: Icons.notifications_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CadetNotificationsScreen(),
                      ),
                    );
                  },
                ),
                _buildActionTile(
                  title: "Help & Support",
                  icon: Icons.headset_mic_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HelpSupportScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Confirm Logout"),
                          content: const Text(
                            "Are you sure you want to logout?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                "Logout",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await AuthService().logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const LoginPage(initialRole: 'officer'),
                            ),
                            (route) => false,
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Logout",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon, {
    bool isFullWidth = false,
  }) {
    return Expanded(
        flex: isFullWidth ? 1 : 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.lightGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: AppTheme.navyBlue.withOpacity(0.7)),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.navyBlue,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ).animate().fade(duration: Duration(milliseconds: 100))
      ..scale(begin: const Offset(0.9, 0.9));
    ;
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.lightGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.navyBlue, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      ),
    );
  }
}
