import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ncc_cadet/cadet/cadet_attendance_report_page.dart';
import 'package:ncc_cadet/cadet/cadet_camp_details_page.dart';
import 'package:ncc_cadet/cadet/cadet_lave_request_screen.dart';
import 'package:ncc_cadet/cadet/cadet_complaint_screen.dart';
import 'package:ncc_cadet/cadet/cadet_leave_history_screen.dart';
import 'package:ncc_cadet/cadet/nav_bars/cadet_notification_screen.dart';
import 'package:ncc_cadet/cadet/nav_bars/cadet_profile_screen.dart';
import 'package:ncc_cadet/officer/manage_cadets_page.dart'; // Import ManageCadetsPage
import 'package:ncc_cadet/providers/user_provider.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:ncc_cadet/common/shimmer_loading.dart';
import 'package:ncc_cadet/officer/mark_attendance_selection_screen.dart';
import 'package:ncc_cadet/cadet/cadet_exam_screen.dart';
import 'package:ncc_cadet/cadet/cadet_documents_screen.dart';

class CadetDashboardScreen extends StatelessWidget {
  const CadetDashboardScreen({super.key});

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
                          user?.name ?? "Cadet",
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
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
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

              const SizedBox(height: 5),
              Text(
                user?.roleId ?? "NCC ID Loading...",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ).animate().fade(delay: 100.ms),

              const SizedBox(height: 25),

              // Overview Section - Wrapped in FutureBuilder/StreamBuilder to fetch data
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('attendance')
                    .where('cadetId', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, attendanceSnapshot) {
                  if (attendanceSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Your Overview",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.navyBlue,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: const [
                            Expanded(child: ShimmerLoading.card(height: 140)),
                            SizedBox(width: 15),
                            Expanded(child: ShimmerLoading.card(height: 140)),
                          ],
                        ),
                      ],
                    );
                  }

                  double attendancePercentage = 0.0;
                  if (attendanceSnapshot.hasData) {
                    final docs = attendanceSnapshot.data!.docs;
                    if (docs.isNotEmpty) {
                      final total = docs.length;
                      final present = docs
                          .where((d) => d['status'] == 'Present')
                          .length;
                      attendancePercentage = (present / total) * 100;
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Your Overview",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.navyBlue,
                        ),
                      ).animate().fade(delay: 200.ms),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: OverviewCard(
                              icon: Icons.assignment_turned_in_outlined,
                              iconColor: AppTheme.navyBlue,
                              title: "Attendance",
                              value:
                                  "${attendancePercentage.toStringAsFixed(1)}%",
                              subtitle: "Overall Percentage",
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('parades')
                                  .where(
                                    'organizationId',
                                    isEqualTo: user?.organizationId,
                                  )
                                  .where(
                                    'date',
                                    isGreaterThanOrEqualTo: DateTime.now()
                                        .toIso8601String()
                                        .split('T')[0],
                                  )
                                  .orderBy('date')
                                  .limit(10)
                                  .snapshots(),
                              builder: (context, paradeSnapshot) {
                                return StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('camps')
                                      .where(
                                        'organizationId',
                                        isEqualTo: user?.organizationId,
                                      )
                                      .where(
                                        'startDate',
                                        isGreaterThanOrEqualTo: DateTime.now()
                                            .toIso8601String()
                                            .split('T')[0],
                                      )
                                      .orderBy('startDate')
                                      .limit(10)
                                      .snapshots(),
                                  builder: (context, campSnapshot) {
                                    if (paradeSnapshot.connectionState ==
                                            ConnectionState.waiting ||
                                        campSnapshot.connectionState ==
                                            ConnectionState.waiting) {
                                      return const ShimmerLoading.card(
                                        height: 140,
                                      );
                                    }

                                    // Find Next Parade
                                    Map<String, dynamic>? nextParade;
                                    if (paradeSnapshot.hasData) {
                                      for (var doc
                                          in paradeSnapshot.data!.docs) {
                                        final data =
                                            doc.data() as Map<String, dynamic>;
                                        final targetYear =
                                            data['targetYear'] ?? 'All';
                                        if (targetYear == 'All' ||
                                            targetYear ==
                                                "${user?.year} Year" ||
                                            targetYear == user?.year) {
                                          nextParade = data;
                                          break;
                                        }
                                      }
                                    }

                                    // Find Next Camp
                                    Map<String, dynamic>? nextCamp;
                                    if (campSnapshot.hasData) {
                                      for (var doc in campSnapshot.data!.docs) {
                                        final data =
                                            doc.data() as Map<String, dynamic>;
                                        final targetYear =
                                            data['targetYear'] ?? 'All';
                                        if (targetYear == 'All' ||
                                            targetYear ==
                                                "${user?.year} Year" ||
                                            targetYear == user?.year) {
                                          nextCamp = data;
                                          break;
                                        }
                                      }
                                    }

                                    // Determine Earliest Event
                                    String title = "Next Event";
                                    String date = "None";
                                    String subtitle = "No upcoming events";
                                    IconData icon =
                                        Icons.calendar_today_outlined;
                                    Color iconColor = Colors.grey;

                                    if (nextParade != null &&
                                        nextCamp != null) {
                                      final paradeDate = DateTime.tryParse(
                                        nextParade['date'] ?? '',
                                      );
                                      final campDate = DateTime.tryParse(
                                        nextCamp['startDate'] ?? '',
                                      );

                                      if (paradeDate != null &&
                                          campDate != null) {
                                        if (paradeDate.isBefore(campDate) ||
                                            paradeDate.isAtSameMomentAs(
                                              campDate,
                                            )) {
                                          // Parade is sooner or same day
                                          title = "Next Parade";
                                          date = DateFormat(
                                            'MMM d, yyyy',
                                          ).format(paradeDate);
                                          subtitle =
                                              nextParade['name'] ??
                                              "Upcoming Parade";
                                          icon = Icons.flag_outlined;
                                          iconColor = AppTheme.gold;
                                        } else {
                                          // Camp is sooner
                                          title = "Next Camp";
                                          date = DateFormat(
                                            'MMM d, yyyy',
                                          ).format(campDate);
                                          subtitle =
                                              nextCamp['name'] ??
                                              "Upcoming Camp";
                                          icon = Icons.terrain_outlined;
                                          iconColor = Colors.green;
                                        }
                                      } else if (paradeDate != null) {
                                        title = "Next Parade";
                                        date = DateFormat(
                                          'MMM d, yyyy',
                                        ).format(paradeDate);
                                        subtitle =
                                            nextParade['name'] ??
                                            "Upcoming Parade";
                                        icon = Icons.flag_outlined;
                                        iconColor = AppTheme.gold;
                                      } else if (campDate != null) {
                                        title = "Next Camp";
                                        date = DateFormat(
                                          'MMM d, yyyy',
                                        ).format(campDate);
                                        subtitle =
                                            nextCamp['name'] ?? "Upcoming Camp";
                                        icon = Icons.terrain_outlined;
                                        iconColor = Colors.green;
                                      }
                                    } else if (nextParade != null) {
                                      title = "Next Parade";
                                      date = DateFormat('MMM d, yyyy').format(
                                        DateTime.parse(nextParade['date']),
                                      );
                                      subtitle =
                                          nextParade['name'] ??
                                          "Upcoming Parade";
                                      icon = Icons.flag_outlined;
                                      iconColor = AppTheme.gold;
                                    } else if (nextCamp != null) {
                                      title = "Next Camp";
                                      date = DateFormat('MMM d, yyyy').format(
                                        DateTime.parse(nextCamp['startDate']),
                                      );
                                      subtitle =
                                          nextCamp['name'] ?? "Upcoming Camp";
                                      icon = Icons.terrain_outlined;
                                      iconColor = Colors.green;
                                    }

                                    return OverviewCard(
                                      icon: icon,
                                      iconColor: iconColor,
                                      title: title,
                                      value: date,
                                      subtitle: subtitle,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ).animate().fade(delay: 300.ms).slideY(begin: 0.1, end: 0),
                    ],
                  );
                },
              ),

              const SizedBox(height: 15),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('leaves')
                    .where('cadetId', isEqualTo: user?.uid)
                    .where('status', isEqualTo: 'Pending')
                    .snapshots(),
                builder: (context, leaveSnapshot) {
                  if (leaveSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const ShimmerLoading.card(height: 80);
                  }
                  int pendingCount = 0;
                  if (leaveSnapshot.hasData) {
                    pendingCount = leaveSnapshot.data!.docs.length;
                  }

                  return LeaveStatusCard(pendingCount: pendingCount);
                },
              ).animate().fade(delay: 400.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 30),

              // Quick Actions Section
              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navyBlue,
                ),
              ).animate().fade(delay: 500.ms),
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
                    "Attendance",
                    Icons.assignment_turned_in_outlined,
                    const CadetAttendanceReportScreen(),
                    0,
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notifications')
                        .where(
                          'type',
                          whereIn: ['global', 'organization', 'cadet'],
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      int count = 0;
                      if (snapshot.hasData) {
                        count = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final targetId = data['targetId'];
                          final isRead = data['isRead'] ?? false;
                          return (targetId == user?.uid) && !isRead;
                        }).length;
                      }
                      return _buildAction(
                        context,
                        "Notifications",
                        Icons.notifications_none_outlined,
                        const CadetNotificationsScreen(),
                        1,
                        badgeCount: count,
                      );
                    },
                  ),
                  _buildAction(
                    context,
                    "Leave Request",
                    Icons.mail_outline,
                    const CadetLeaveRequestScreen(),
                    2,
                  ),
                  _buildAction(
                    context,
                    "Camp Details",
                    Icons.terrain_outlined,
                    const CadetCampDetailsScreen(),
                    3,
                  ),
                  _buildAction(
                    context,
                    "Exams",
                    Icons.assignment_turned_in,
                    const CadetExamScreen(),
                    4,
                  ),
                  _buildAction(
                    context,
                    "Digital Records",
                    Icons.folder_shared_outlined,
                    const CadetDocumentsScreen(),
                    5,
                  ),
                  _buildAction(
                    context,
                    "Profile",
                    Icons.account_box_outlined,
                    const CadetProfileScreen(),
                    6,
                  ),
                  _buildAction(
                    context,
                    "Complaints",
                    Icons.comment_outlined,
                    const CadetComplaintScreen(),
                    7,
                  ),
                  if (user?.rank == 'Senior Under Officer')
                    _buildAction(
                      context,
                      "Mark Attendance",
                      Icons.check_circle_outline,
                      const MarkAttendanceSelectionScreen(),
                      8,
                    ),
                  if (user?.rank == 'Senior Under Officer')
                    _buildAction(
                      context,
                      "Manage Cadets",
                      Icons.people_outline,
                      const ManageCadetsPage(),
                      9,
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
    int index, {
    int badgeCount = 0,
  }) {
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: AppTheme.navyBlue, size: 32),
                    if (badgeCount > 0)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
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
        .fade(delay: (600 + (index * 100)).ms)
        .scale(begin: const Offset(0.9, 0.9));
  }
}

class OverviewCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  const OverviewCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class LeaveStatusCard extends StatelessWidget {
  final int pendingCount;
  const LeaveStatusCard({super.key, this.pendingCount = 0});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CadetLeaveHistoryScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.navyBlue, AppTheme.navyBlue.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.navyBlue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Leave Request Status",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      pendingCount > 0 ? "Pending" : "Check History",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (pendingCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.gold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "$pendingCount Action${pendingCount > 1 ? 's' : ''}",
                          style: const TextStyle(
                            color: AppTheme.navyBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
