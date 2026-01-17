import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/services/attendance_service.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/services/parade_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:ncc_cadet/utils/access_control.dart';
import 'package:intl/intl.dart';

class OfficerAttendanceReport extends StatefulWidget {
  const OfficerAttendanceReport({super.key});

  @override
  State<OfficerAttendanceReport> createState() =>
      _OfficerAttendanceReportState();
}

class _OfficerAttendanceReportState extends State<OfficerAttendanceReport> {
  final AuthService _authService = AuthService();
  final AttendanceService _attendanceService = AttendanceService();
  final ParadeService _paradeService = ParadeService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _authService.getUserProfile(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.lightGrey,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.accentBlue),
            ),
          );
        }
        final officer = userSnapshot.data;
        if (officer == null) {
          return const Scaffold(
            body: Center(child: Text("Error: Officer profile not found")),
          );
        }

        final manageableYears = getManageableYears(officer);
        final bool isRestricted = manageableYears != null;
        final bool singleYearView = isRestricted && manageableYears.length == 1;

        return DefaultTabController(
          length: singleYearView ? 1 : 4,
          child: Scaffold(
            backgroundColor: AppTheme.lightGrey,
            appBar: AppBar(
              backgroundColor: AppTheme.navyBlue,
              elevation: 0,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_left,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                "Unit Attendance Report",
                style: TextStyle(color: Colors.white),
              ),
              bottom: singleYearView
                  ? null
                  : TabBar(
                      labelColor: AppTheme.accentBlue,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppTheme.accentBlue,
                      tabs: const [
                        Tab(text: "All"),
                        Tab(text: "1st Year"),
                        Tab(text: "2nd Year"),
                        Tab(text: "3rd Year"),
                      ],
                    ),
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: _authService.getCadetsStream(
                officer.organizationId,
                years: manageableYears,
              ),
              builder: (context, cadetSnapshot) {
                if (!cadetSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final cadets = cadetSnapshot.data!.docs;

                return StreamBuilder<QuerySnapshot>(
                  stream: _attendanceService.getOrganizationAttendance(
                    officer.organizationId,
                  ),
                  builder: (context, attendanceSnapshot) {
                    if (!attendanceSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final attendance = attendanceSnapshot.data!.docs;

                    return StreamBuilder<QuerySnapshot>(
                      stream: _paradeService.getParadesStream(
                        officer.organizationId,
                      ),
                      builder: (context, paradeSnapshot) {
                        if (!paradeSnapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final parades = paradeSnapshot.data!.docs;

                        if (singleYearView) {
                          return _buildReportContent(
                            manageableYears.first,
                            cadets,
                            attendance,
                            parades,
                          );
                        }

                        return TabBarView(
                          children: [
                            _buildReportContent(
                              "All",
                              cadets,
                              attendance,
                              parades,
                            ),
                            _buildReportContent(
                              "1st Year",
                              cadets,
                              attendance,
                              parades,
                            ),
                            _buildReportContent(
                              "2nd Year",
                              cadets,
                              attendance,
                              parades,
                            ),
                            _buildReportContent(
                              "3rd Year",
                              cadets,
                              attendance,
                              parades,
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportContent(
    String year,
    List<QueryDocumentSnapshot> allCadets,
    List<QueryDocumentSnapshot> allAttendance,
    List<QueryDocumentSnapshot> allParades,
  ) {
    // 1. Filter Cadets by Year
    final filteredCadets = year == 'All'
        ? allCadets
        : allCadets.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['year'] == year;
          }).toList();

    final targetCadetIds = filteredCadets.map((e) => e.id).toSet();

    // 2. Filter Attendance by Cadet IDs (Target Group)
    final filteredAttendance = allAttendance.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return targetCadetIds.contains(data['cadetId']);
    }).toList();

    // 3. Filter Parades (that have happened)
    // We only care about past parades or today's parades for reports basically
    final now = DateTime.now();
    final pastParades = allParades.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final dateStr = data['date'] as String;
      // Simple string comparison works for ISO dates, but let's be safe if format varies
      // Assuming YYYY-MM-DD from other files
      return dateStr.compareTo(DateFormat('yyyy-MM-dd').format(now)) <= 0;
    }).toList();

    // Re-sort past parades descending (most recent first)
    pastParades.sort((a, b) {
      final dA = (a.data() as Map<String, dynamic>)['date'];
      final dB = (b.data() as Map<String, dynamic>)['date'];
      return dB.compareTo(dA);
    });

    // 4. Calculate Stats
    final totalRecords = filteredAttendance.length;
    final presentCount = filteredAttendance
        .where(
          (doc) => (doc.data() as Map<String, dynamic>)['status'] == 'Present',
        )
        .length;
    final absentCount = filteredAttendance
        .where(
          (doc) => (doc.data() as Map<String, dynamic>)['status'] == 'Absent',
        )
        .length;
    final excusedCount = filteredAttendance
        .where(
          (doc) => (doc.data() as Map<String, dynamic>)['status'] == 'Excused',
        )
        .length;

    final double avgAttendance = totalRecords == 0
        ? 0.0
        : (presentCount / totalRecords);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Unit Overview ($year)"),
          const SizedBox(height: 12),
          _buildUnitSummaryCard(avgAttendance),
          const SizedBox(height: 28),

          _sectionTitle("Status Breakdown"),
          const SizedBox(height: 12),
          _buildBreakdownRow(presentCount, absentCount, excusedCount),
          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle("Recent Parades"),
              // TextButton(onPressed: () {}, child: const Text("View All")),
            ],
          ),
          const SizedBox(height: 8),
          _buildParadeList(pastParades, filteredAttendance, targetCadetIds),
        ],
      ),
    );
  }

  // ---------------- UI COMPONENTS ----------------

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildUnitSummaryCard(double percentage) {
    final percString = "${(percentage * 100).toStringAsFixed(1)}%";
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardStyle(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Average Attendance",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    percString,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlueBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: AppTheme.accentBlue,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: AppTheme.lightBlueBg,
              valueColor: const AlwaysStoppedAnimation(AppTheme.accentBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(int present, int absent, int excused) {
    return Row(
      children: [
        _buildSmallStatCard("Present", "$present", Colors.green),
        const SizedBox(width: 12),
        _buildSmallStatCard("Absent", "$absent", Colors.red),
        const SizedBox(width: 12),
        _buildSmallStatCard("On Leave", "$excused", Colors.orange),
      ],
    );
  }

  Widget _buildSmallStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: _cardStyle(),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParadeList(
    List<QueryDocumentSnapshot> parades,
    List<QueryDocumentSnapshot> attendanceRecords,
    Set<String> targetCadetIds,
  ) {
    if (parades.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text("No recent parades found"),
        ),
      );
    }

    // Limit to latest 5
    final recentParades = parades.take(5).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentParades.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final paradeDoc = recentParades[index];
        final paradeData = paradeDoc.data() as Map<String, dynamic>;
        final paradeId = paradeDoc.id;

        // Calculate stats for this specific parade & year group
        // Filter records for this parade AND our target cadets
        final paradeRecords = attendanceRecords.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['paradeId'] == paradeId;
        }).toList();

        final total = paradeRecords.length;
        final present = paradeRecords
            .where(
              (doc) =>
                  (doc.data() as Map<String, dynamic>)['status'] == 'Present',
            )
            .length;

        // If no records found for this parade (attendance not taken), show N/A
        final percString = total == 0
            ? "N/A"
            : "${((present / total) * 100).toStringAsFixed(0)}%";

        return Container(
          decoration: _cardStyle(),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            title: Text(
              paradeData['name'] ?? 'Parade',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              DateFormat(
                'MMM d, yyyy',
              ).format(DateTime.parse(paradeData['date'])),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  percString,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                // const SizedBox(width: 6),
                // const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            // onTap: () {},
          ),
        );
      },
    );
  }

  BoxDecoration _cardStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: AppTheme.navyBlue.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
