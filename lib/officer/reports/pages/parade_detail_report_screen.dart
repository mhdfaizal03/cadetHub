import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ncc_cadet/services/pdf_generator_service.dart';
import 'package:ncc_cadet/utils/theme.dart';

class ParadeDetailReportScreen extends StatefulWidget {
  final QueryDocumentSnapshot paradeDoc;
  final List<QueryDocumentSnapshot> attendanceRecords;
  final List<QueryDocumentSnapshot> allCadets; // To map ID to Name

  const ParadeDetailReportScreen({
    super.key,
    required this.paradeDoc,
    required this.attendanceRecords,
    required this.allCadets,
  });

  @override
  State<ParadeDetailReportScreen> createState() =>
      _ParadeDetailReportScreenState();
}

class _ParadeDetailReportScreenState extends State<ParadeDetailReportScreen> {
  final PdfGeneratorService _pdfService = PdfGeneratorService();

  @override
  Widget build(BuildContext context) {
    final paradeData = widget.paradeDoc.data() as Map<String, dynamic>;
    final paradeId = widget.paradeDoc.id;

    // Filter attendance for this parade only
    final records = widget.attendanceRecords
        .where((doc) => (doc.data() as Map)['paradeId'] == paradeId)
        .toList();

    // Stats
    final total = records.length;
    final present = records
        .where((d) => (d.data() as Map)['status'] == 'Present')
        .length;
    final absent = records
        .where((d) => (d.data() as Map)['status'] == 'Absent')
        .length;

    // Calculate percentage
    final perc = total == 0 ? 0.0 : (present / total) * 100;

    final name = paradeData['name'] ?? 'Parade';
    final dateStr = paradeData['date'] ?? '';
    final date = DateTime.tryParse(dateStr);

    // Sort records by cadet name
    records.sort((a, b) {
      final aId = (a.data() as Map)['cadetId'];
      final bId = (b.data() as Map)['cadetId'];
      final aName = _getCadetName(aId);
      final bName = _getCadetName(bId);
      return aName.compareTo(bName);
    });

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text("Parade Report"),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navyBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        date != null
                            ? DateFormat('EEEE, MMMM d, yyyy').format(date)
                            : dateStr,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (paradeData['time'] != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          paradeData['time'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats
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
                  _statItem("Absent", "$absent", color: Colors.red),
                  _statItem(
                    "Attendance",
                    "${perc.toStringAsFixed(1)}%",
                    color: AppTheme.navyBlue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text("Download Parade Report"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navyBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Downloading...")),
                  );
                  await _pdfService.generateParadeListPDF(
                    parades: [widget.paradeDoc],
                    attendanceRecords: widget.attendanceRecords,
                    title: "Parade Report: $name",
                    subtitle: date != null
                        ? DateFormat('MMM d, yyyy').format(date)
                        : "",
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "Attendees",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final r = records[index].data() as Map<String, dynamic>;
                final cadetId = r['cadetId'];
                final status = r['status'] ?? 'Absent';
                final cName = _getCadetName(cadetId);

                Color stColor = Colors.red;
                if (status == 'Present') stColor = Colors.green;
                if (status == 'Excused') stColor = Colors.orange;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.lightBlueBg,
                      child: Text(cName.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(
                      cName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(cadetId),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: stColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: stColor,
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

  String _getCadetName(String id) {
    try {
      final cadet = widget.allCadets.firstWhere((c) => c.id == id);
      return (cadet.data() as Map)['name'] ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
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
