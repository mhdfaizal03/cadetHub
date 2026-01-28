import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:ncc_cadet/models/attendance_model.dart';
import 'package:ncc_cadet/providers/user_provider.dart';
import 'package:ncc_cadet/services/attendance_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:ncc_cadet/services/parade_service.dart'; // Import ParadeService

class CadetParadesScreen extends StatefulWidget {
  const CadetParadesScreen({super.key});

  @override
  State<CadetParadesScreen> createState() => _CadetParadesScreenState();
}

class _CadetParadesScreenState extends State<CadetParadesScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final ParadeService _paradeService = ParadeService();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not found")));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.lightGrey,
        appBar: AppBar(
          backgroundColor: AppTheme.navyBlue,
          elevation: 0,
          foregroundColor: Colors.white,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_left, size: 30),
          ),
          title: const Text(
            "Parades",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: AppTheme.gold,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Upcoming"),
              Tab(text: "Attendance History"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUpcomingParades(user.organizationId, user.year),
            _buildAttendanceHistory(user.uid),
          ],
        ),
      ),
    );
  }

  // --- Upcoming Parades Tab ---
  Widget _buildUpcomingParades(String organizationId, String userYear) {
    return StreamBuilder<QuerySnapshot>(
      stream: _paradeService.getUpcomingParades(organizationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState("No upcoming parades scheduled.");
        }

        // Filter by Year (Client-side)
        final parades = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final targetYear = data['targetYear'] ?? 'All';
          return targetYear == 'All' ||
              targetYear == userYear ||
              targetYear == "$userYear Year"; // Handle variants
        }).toList();

        if (parades.isEmpty) {
          return _buildEmptyState("No upcoming parades for your year.");
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: parades.length,
          itemBuilder: (context, index) {
            final data = parades[index].data() as Map<String, dynamic>;
            final date = DateTime.parse(data['date']);
            final formattedDate = DateFormat('EEE, MMM d, yyyy').format(date);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.navyBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.flag_outlined,
                    color: AppTheme.navyBlue,
                  ),
                ),
                title: Text(
                  data['name'] ?? "Parade",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          data['time'] ?? "",
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (data['location'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            data['location'],
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ).animate().fade().slideY(begin: 0.1, end: 0);
          },
        );
      },
    );
  }

  // --- Attendance History Tab ---
  Widget _buildAttendanceHistory(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _attendanceService.getCadetAttendance(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState("No attendance records found.");
        }

        final records = snapshot.data!.docs.map((doc) {
          return AttendanceModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        // Calculate Stats
        final total = records.length;
        final present = records.where((r) => r.status == 'Present').length;
        final percentage = total == 0 ? 0.0 : (present / total);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Attendance Card
              AttendanceSummaryCard(
                percentage: percentage,
                total: total,
                present: present,
              ),
              const SizedBox(height: 16),
              const Text(
                "History",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navyBlue,
                ),
              ),
              const SizedBox(height: 10),

              // Attendance List/Table
              AttendanceList(records: records),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class AttendanceSummaryCard extends StatelessWidget {
  final double percentage;
  final int total;
  final int present;

  const AttendanceSummaryCard({
    super.key,
    required this.percentage,
    required this.total,
    required this.present,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Overall Attendance",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                "${(percentage * 100).toStringAsFixed(0)}%",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0052D4),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF0F4FF),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF0052D4),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Attended $present out of $total parades",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class AttendanceList extends StatelessWidget {
  final List<AttendanceModel> records;
  const AttendanceList({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          // Table Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text(
                    "Date",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Parade Name",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Status",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: records.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final record = records[index];
              final isPresent = record.status == "Present";
              final isExcused = record.status == "Excused";

              Color statusColor = const Color(0xFFE52D27); // Absent - Red
              if (isPresent)
                statusColor = const Color(0xFF76BA1B); // Present - Green
              if (isExcused) statusColor = Colors.orange; // Excused - Orange

              final dateStr = DateFormat(
                'MMM d, yyyy',
              ).format(DateTime.parse(record.date));

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        dateStr,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "Drill Parade", // Placeholder since we don't assume join
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            record.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Helper for card styling
BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade200),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.02),
        blurRadius: 5,
        offset: const Offset(0, 2),
      ),
    ],
  );
}
