import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ncc_cadet/officer/approve_cadet_screen.dart';
import 'package:provider/provider.dart';
import 'package:ncc_cadet/cadet/nav_bars/cadet_notification_screen.dart';

import 'package:ncc_cadet/officer/leave_approval_page.dart';
import 'package:ncc_cadet/officer/manage_cadets_page.dart';
import 'package:ncc_cadet/officer/officer_attendance_report_page.dart';
import 'package:ncc_cadet/officer/parade_list_screen.dart';
import 'package:ncc_cadet/officer/send_notifications_page.dart';
import 'package:ncc_cadet/providers/user_provider.dart';
import 'package:ncc_cadet/officer/officer_camp_list_screen.dart';
import 'package:ncc_cadet/officer/officer_complaint_list_screen.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/officer/mark_attendance_selection_screen.dart';
import 'package:ncc_cadet/services/attendance_service.dart';
import 'package:ncc_cadet/utils/theme.dart';

class OfficerDashboardScreen extends StatelessWidget {
  const OfficerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome,",
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                        Text(
                          user?.name ?? "Officer",
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navyBlue,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.navyBlue.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CadetNotificationsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppTheme.navyBlue,
                      ),
                    ),
                  ),
                ],
              ).animate().fade().slideX(begin: -0.1, end: 0),

              const SizedBox(height: 10),

              // Overview Section
              const Text(
                "Overview",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navyBlue,
                ),
              ).animate().fade(delay: 200.ms),
              const SizedBox(height: 15),
              StreamBuilder<QuerySnapshot>(
                stream: AuthService().getCadetsStream(user!.organizationId),
                builder: (context, cadetSnapshot) {
                  final cadetCount = cadetSnapshot.hasData
                      ? cadetSnapshot.data!.docs.length
                      : 0;

                  return StreamBuilder<QuerySnapshot>(
                    stream: AttendanceService().getOrganizationAttendance(
                      user.organizationId,
                    ),
                    builder: (context, attendanceSnapshot) {
                      String attendancePercentage = "0%";

                      if (attendanceSnapshot.hasData &&
                          attendanceSnapshot.data!.docs.isNotEmpty) {
                        final totalRecords =
                            attendanceSnapshot.data!.docs.length;
                        final presentCount = attendanceSnapshot.data!.docs
                            .where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return data['status'] == 'Present';
                            })
                            .length;

                        if (totalRecords > 0) {
                          attendancePercentage =
                              "${((presentCount / totalRecords) * 100).toStringAsFixed(1)}%";
                        }
                      }

                      return Row(
                            children: [
                              Expanded(
                                child: OverviewCard(
                                  icon: Icons.group_outlined,
                                  iconColor: AppTheme.navyBlue,
                                  title: "Total Cadets",
                                  value: "$cadetCount",
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: OverviewCard(
                                  icon: Icons.calendar_month_outlined,
                                  iconColor: AppTheme.gold,
                                  title: "Attendance",
                                  value: attendancePercentage,
                                ),
                              ),
                            ],
                          )
                          .animate()
                          .fade(delay: 300.ms)
                          .slideY(begin: 0.1, end: 0);
                    },
                  );
                },
              ),

              const SizedBox(height: 15),

              // Quick Actions Section
              const Text(
                "Admin Actions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navyBlue,
                ),
              ).animate().fade(delay: 400.ms),

              const SizedBox(height: 15),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.3,
                children: [
                  _buildAction(
                    context,
                    "Mark Attendance",
                    Icons.check_circle_outline,
                    const MarkAttendanceSelectionScreen(),
                    0,
                  ),
                  _buildAction(
                    context,
                    "Add/Edit Parade",
                    Icons.add_circle_outline_outlined,
                    const ParadeListScreen(),
                    1,
                  ),
                  _buildAction(
                    context,
                    "Manage Cadets",
                    Icons.group_outlined,
                    const ManageCadetsPage(),
                    2,
                  ),
                  _buildAction(
                    context,
                    "Reports",
                    Icons.list,
                    const OfficerAttendanceReport(),
                    3,
                  ),
                  _buildAction(
                    context,
                    "Notifications",
                    Icons.mail_outline,
                    const SendNotificationPage(),
                    4,
                  ),
                  _buildAction(
                    context,
                    "Approve Leave",
                    Icons.security_outlined,
                    const ApproveLeavePage(),
                    5,
                  ),
                  // Camp Management
                  _buildAction(
                    context,
                    "Manage Camps",
                    Icons.terrain,
                    const OfficerCampListScreen(),
                    6,
                  ),
                  // Complaint Management
                  _buildAction(
                    context,
                    "Complaints",
                    Icons.report_problem_outlined,
                    const OfficerComplaintListScreen(),
                    7,
                  ),
                  _buildAction(
                    context,
                    "Approve Cadets",
                    Icons.approval_outlined,
                    const ApproveCadetPage(),
                    8,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction(
    BuildContext context,
    String label,
    IconData icon,
    Widget? page,
    int index,
  ) {
    return InkWell(
          onTap: () {
            if (page != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => page),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.navyBlue.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppTheme.navyBlue, size: 32),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fade(delay: (500 + (index * 100)).ms)
        .scale(begin: const Offset(0.95, 0.95));
  }
}

class OverviewCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const OverviewCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navyBlue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppTheme.navyBlue,
            ),
          ),
        ],
      ),
    );
  }
}
