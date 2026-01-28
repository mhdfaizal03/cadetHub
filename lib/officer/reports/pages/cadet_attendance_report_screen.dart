import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ncc_cadet/utils/theme.dart';

class CadetAttendanceReportScreen extends StatelessWidget {
  final String cadetId;
  final String cadetName;
  final List<QueryDocumentSnapshot> attendanceRecords;
  final List<QueryDocumentSnapshot> allParades;

  const CadetAttendanceReportScreen({
    super.key,
    required this.cadetId,
    required this.cadetName,
    required this.attendanceRecords,
    required this.allParades,
  });

  @override
  Widget build(BuildContext context) {
    // Merge attendance with parade info
    final history = attendanceRecords.map((att) {
      final data = att.data() as Map<String, dynamic>;
      final paradeId = data['paradeId'];
      final parade = allParades.firstWhere(
        (p) => p.id == paradeId,
        orElse: () => allParades.first,
      );
      final pData = parade.data() as Map<String, dynamic>;

      return {
        'paradeName': pData['name'] ?? 'Parade',
        'date': DateTime.parse(pData['date']),
        'status': data['status'] ?? 'Absent',
      };
    }).toList();

    // Sort by date desc
    history.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );

    final present = history.where((h) => h['status'] == 'Present').length;
    final total = history.length;
    final perc = total == 0 ? 0.0 : (present / total) * 100;

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: Text("$cadetName's Attendance"),
        backgroundColor: AppTheme.navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem("Total", "$total"),
                  _statItem("Present", "$present", color: Colors.green),
                  _statItem("Absent", "${total - present}", color: Colors.red),
                  _statItem(
                    "Percentage",
                    "${perc.toStringAsFixed(0)}%",
                    color: AppTheme.navyBlue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (history.isEmpty)
              const Center(child: Text("No attendance records found."))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = history[index];
                  final status = item['status'] as String;
                  Color statusColor = Colors.red;
                  if (status == 'Present') statusColor = Colors.green;
                  if (status == 'Excused') statusColor = Colors.orange;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        item['paradeName'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        DateFormat(
                          'EEEE, MMM d, yyyy',
                        ).format(item['date'] as DateTime),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, {Color color = Colors.black}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
