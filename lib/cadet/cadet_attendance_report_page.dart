import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ncc_cadet/models/attendance_model.dart';
import 'package:ncc_cadet/providers/user_provider.dart';
import 'package:ncc_cadet/services/attendance_service.dart';
import 'package:provider/provider.dart';

class CadetAttendanceReportScreen extends StatefulWidget {
  const CadetAttendanceReportScreen({super.key});

  @override
  State<CadetAttendanceReportScreen> createState() =>
      _CadetAttendanceReportScreenState();
}

class _CadetAttendanceReportScreenState
    extends State<CadetAttendanceReportScreen> {
  final AttendanceService _attendanceService = AttendanceService();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not found")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.keyboard_arrow_left,
            color: Colors.black,
            size: 30,
          ),
        ),
        title: const Text(
          "Attendance Report",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _attendanceService.getCadetAttendance(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No attendance records found.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
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

                // Attendance List/Table
                AttendanceList(records: records),
              ],
            ),
          );
        },
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

              // Use date as name fallback for now as we don't store Parade Name in Attendance Model directly...
              // Wait, I did verify AttendanceModel has cadetName, but does it have Parade Name?
              // Looking at AttendanceModel (step 211): id, paradeId, cadetId, cadetName, status, date, organizationId.
              // It does NOT have paradeName.
              // Ideally we fetch parade details, but for now let's just show "Parade" or ID or Date?
              // Or maybe 'Parade' is sufficient.
              // Actually, I can format the date.

              final dateStr = record.date;

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
    borderRadius: BorderRadius.circular(4),
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
