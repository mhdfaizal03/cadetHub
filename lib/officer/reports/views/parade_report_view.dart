import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/services/parade_service.dart';
import 'package:ncc_cadet/services/attendance_service.dart';
import 'package:ncc_cadet/services/pdf_generator_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:ncc_cadet/utils/access_control.dart';
import 'package:intl/intl.dart';
import 'package:ncc_cadet/officer/reports/pages/parade_detail_report_screen.dart';

class ParadeReportView extends StatefulWidget {
  const ParadeReportView({super.key});

  @override
  State<ParadeReportView> createState() => _ParadeReportViewState();
}

class _ParadeReportViewState extends State<ParadeReportView> {
  final AuthService _authService = AuthService();
  final ParadeService _paradeService = ParadeService();
  final AttendanceService _attendanceService = AttendanceService();
  final PdfGeneratorService _pdfService = PdfGeneratorService();

  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // We need 'cadets' for the detail screen.
    // Let's refactor the build method to fetch cadets first.
    // Since this is becoming complex with nested streams, maybe I should wrap them differently
    // or just fetch cadets inside the detail screen?
    // User wants "corrected implementation". Fetching inside detail might rely on passing ID.
    // But passing list is better for synchronous lookup.
    // Recommendation: Add Cadets Stream to this file.

    // I will replace start of build method to include Cadet Stream.
    return FutureBuilder<UserModel?>(
      future: _authService.getUserProfile(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final officer = userSnapshot.data!;

        return StreamBuilder<QuerySnapshot>(
          stream: _authService.getCadetsStream(
            officer.organizationId,
            years: getManageableYears(officer),
          ),
          builder: (context, cadetSnapshot) {
            if (!cadetSnapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final cadets = cadetSnapshot.data!.docs;

            return StreamBuilder<QuerySnapshot>(
              stream: _paradeService.getParadesStream(officer.organizationId),
              builder: (context, paradeSnapshot) {
                // ... rest of stream chain ...
                if (!paradeSnapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final parades = paradeSnapshot.data!.docs;

                return StreamBuilder<QuerySnapshot>(
                  stream: _attendanceService.getOrganizationAttendance(
                    officer.organizationId,
                  ),
                  builder: (context, attSnapshot) {
                    // ...
                    if (!attSnapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final attendance = attSnapshot.data!.docs;

                    // ... existing filter logic ...
                    // Filter Parades
                    List<QueryDocumentSnapshot> filteredParades = parades.where(
                      (doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final dateStr = data['date'] as String;
                        final date = DateTime.parse(dateStr);
                        bool inRange = true;
                        if (_startDate != null)
                          inRange = inRange && !date.isBefore(_startDate!);
                        if (_endDate != null)
                          inRange =
                              inRange &&
                              !date.isAfter(
                                _endDate!.add(const Duration(days: 1)),
                              );
                        return inRange;
                      },
                    ).toList();

                    // Sort desc based on date
                    filteredParades.sort(
                      (a, b) => (b.data() as Map)['date'].compareTo(
                        (a.data() as Map)['date'],
                      ),
                    );

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // ... Filters and Download button (Keep as is) ...
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: _pickDateRange,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: "Filter by Date Range",
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_month),
                                ),
                                child: Text(
                                  _startDate == null
                                      ? "All Parades"
                                      : "${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}",
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.file_download),
                              label: const Text("Download Parade Report"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.navyBlue,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                await _pdfService.generateParadeListPDF(
                                  parades: filteredParades,
                                  attendanceRecords: attendance,
                                  title: "Parade Report",
                                  subtitle: _startDate == null
                                      ? "All Parades"
                                      : "${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}",
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredParades.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (ctx, index) {
                              final pDoc = filteredParades[index];
                              final p = pDoc.data() as Map<String, dynamic>;
                              final pid = pDoc.id;

                              // Quick stats
                              final records = attendance
                                  .where(
                                    (d) => (d.data() as Map)['paradeId'] == pid,
                                  )
                                  .toList();
                              final present = records
                                  .where(
                                    (d) =>
                                        (d.data() as Map)['status'] ==
                                        'Present',
                                  )
                                  .length;
                              final total = records.length;
                              final perc = total == 0
                                  ? "N/A"
                                  : "${((present / total) * 100).toStringAsFixed(0)}%";

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(
                                    p['name'] ?? 'Parade',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    DateFormat(
                                      'EEEE, MMM d, yyyy',
                                    ).format(DateTime.parse(p['date'])),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.lightBlueBg,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          "Att: $perc",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.accentBlue,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ParadeDetailReportScreen(
                                              paradeDoc: pDoc,
                                              attendanceRecords: attendance,
                                              allCadets: cadets,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
