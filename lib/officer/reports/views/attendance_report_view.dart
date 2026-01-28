import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/services/attendance_service.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/services/parade_service.dart';
import 'package:ncc_cadet/services/pdf_generator_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:ncc_cadet/utils/access_control.dart';
import 'package:intl/intl.dart';
import 'package:ncc_cadet/services/exam_service.dart';
import 'package:ncc_cadet/models/exam_model.dart';
import 'package:ncc_cadet/models/exam_result_model.dart';
import 'package:ncc_cadet/officer/reports/pages/cadet_attendance_report_screen.dart';

class AttendanceReportView extends StatefulWidget {
  const AttendanceReportView({super.key});

  @override
  State<AttendanceReportView> createState() => _AttendanceReportViewState();
}

class _AttendanceReportViewState extends State<AttendanceReportView> {
  final AuthService _authService = AuthService();
  final AttendanceService _attendanceService = AttendanceService();
  final ParadeService _paradeService = ParadeService();
  final PdfGeneratorService _pdfService = PdfGeneratorService();

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedYear = 'All';

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
    return FutureBuilder<UserModel?>(
      future: _authService.getUserProfile(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final officer = userSnapshot.data;
        if (officer == null) return const Center(child: Text("Error"));

        final manageableYears = getManageableYears(officer);
        List<String> yearOptions = ['All', '1st Year', '2nd Year', '3rd Year'];
        if (manageableYears != null) {
          yearOptions = manageableYears;
          if (!yearOptions.contains(_selectedYear)) {
            _selectedYear = yearOptions.first;
          }
        }

        return StreamBuilder<QuerySnapshot>(
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
                      return const Center(child: CircularProgressIndicator());
                    }
                    final parades = paradeSnapshot.data!.docs;

                    return _buildContent(
                      cadets,
                      attendance,
                      parades,
                      yearOptions,
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

  Widget _buildContent(
    List<QueryDocumentSnapshot> allCadets,
    List<QueryDocumentSnapshot> allAttendance,
    List<QueryDocumentSnapshot> allParades,
    List<String> yearOptions,
  ) {
    // 1. Filter Cadets by Year
    final filteredCadets = allCadets.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (_selectedYear == 'All') return true;
      return data['year'] == _selectedYear;
    }).toList();
    final targetCadetIds = filteredCadets.map((e) => e.id).toSet();

    // 2. Filter Parades by Date
    List<QueryDocumentSnapshot> filteredParades = allParades.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final dateStr = data['date'] as String;
      final date = DateTime.parse(dateStr);
      bool inRange = true;
      if (_startDate != null) inRange = inRange && !date.isBefore(_startDate!);
      if (_endDate != null) {
        inRange =
            inRange && !date.isAfter(_endDate!.add(const Duration(days: 1)));
      }
      return inRange;
    }).toList();

    // Sort
    filteredParades.sort(
      (a, b) => (b.data() as Map)['date'].compareTo((a.data() as Map)['date']),
    );

    // 3. Filter Attendance
    final targetParadeIds = filteredParades.map((e) => e.id).toSet();
    final filteredAttendance = allAttendance.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return targetCadetIds.contains(data['cadetId']) &&
          targetParadeIds.contains(data['paradeId']);
    }).toList();

    // Stats
    final total = filteredAttendance.length;
    final present = filteredAttendance
        .where((d) => (d.data() as Map)['status'] == 'Present')
        .length;
    final absent = filteredAttendance
        .where((d) => (d.data() as Map)['status'] == 'Absent')
        .length;
    final excused = filteredAttendance
        .where((d) => (d.data() as Map)['status'] == 'Excused')
        .length;
    final avg = total == 0 ? 0.0 : (present / total);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Filter Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: yearOptions.contains(_selectedYear)
                            ? _selectedYear
                            : yearOptions.first,
                        decoration: const InputDecoration(
                          labelText: "Year Group",
                          border: OutlineInputBorder(),
                        ),
                        items: yearOptions
                            .map(
                              (y) => DropdownMenuItem(value: y, child: Text(y)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedYear = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDateRange,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Date Range",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.date_range),
                    ),
                    child: Text(
                      _startDate == null
                          ? "All Dates"
                          : "${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}",
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Overview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Overall Attendance",
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      "${(avg * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentBlue,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 60,
                  width: 60,
                  child: CircularProgressIndicator(
                    value: avg,
                    strokeWidth: 8,
                    color: AppTheme.accentBlue,
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ... stats cards above ... (Keep existing stats row)
          Row(
            children: [
              Expanded(child: _statCard("Present", "$present", Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _statCard("Absent", "$absent", Colors.red)),
              const SizedBox(width: 12),
              Expanded(child: _statCard("Excused", "$excused", Colors.orange)),
            ],
          ),
          const SizedBox(height: 30),

          // Download Action
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text("Download Full Attendance Report"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navyBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await _pdfService.generateAttendancePDF(
                  attendanceRecords: filteredAttendance,
                  parades: filteredParades,
                  title: "Attendance Report - $_selectedYear",
                  dateRange: _startDate == null
                      ? "All Time"
                      : "${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}",
                  unitSummary:
                      "Avg: ${(avg * 100).toStringAsFixed(1)}% | Pres: $present | Abs: $absent | Exc: $excused",
                );
              },
            ),
          ),

          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 10),

          // Cadet List Section
          Text(
            "Individual Cadet Reports",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.navyBlue,
            ),
          ),
          const SizedBox(height: 10),

          if (filteredCadets.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("No Cadets Found"),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredCadets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final doc = filteredCadets[index];
                final data = doc.data() as Map<String, dynamic>;
                final uid = doc.id;
                final name = data['name'] ?? 'Unknown';

                // Calculate Individual Stats
                // Filter attendance for this cadet AND the current date/parade filters
                final cadetAttendance = filteredAttendance.where((att) {
                  return (att.data() as Map)['cadetId'] == uid;
                }).toList();

                final cTotal = filteredParades
                    .length; // Denominator is total filtered parades
                // Or should denominator be parades they were supposed to attend?
                // For simplicity, let's use the filtered parades count if using Year filter,
                // assuming all parades in that year are mandatory.

                // Actual present count
                final cPresent = cadetAttendance
                    .where((att) => (att.data() as Map)['status'] == 'Present')
                    .length;
                final cPerc = cTotal == 0 ? 0.0 : (cPresent / cTotal);

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.navyBlue.withOpacity(0.1),
                      child: Text(
                        name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: AppTheme.navyBlue),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${data['cadetId'] ?? ''} • ${data['year'] ?? ''}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${(cPerc * 100).toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cPerc < 0.75 ? Colors.red : Colors.green,
                            fontSize: 16,
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
                    onTap: () => _showCadetOptions(
                      uid,
                      data,
                      filteredParades,
                      cadetAttendance,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
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
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _showCadetOptions(
    String uid,
    Map<String, dynamic> cadetData,
    List<QueryDocumentSnapshot> parades,
    List<QueryDocumentSnapshot> attendance,
  ) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Actions for ${cadetData['name']}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.purple),
                title: const Text("Generate Comprehensive Report"),
                subtitle: const Text("Includes Attendance & Exam Results"),
                onTap: () async {
                  Navigator.pop(context); // Close sheet
                  await _generateIndividualReport(uid, cadetData);
                },
              ),
              ListTile(
                leading: const Icon(Icons.list_alt, color: Colors.blue),
                title: const Text("View Attendance History"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CadetAttendanceReportScreen(
                        cadetId: uid,
                        cadetName: cadetData['name'] ?? 'Cadet',
                        attendanceRecords: attendance,
                        allParades: parades,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generateIndividualReport(
    String uid,
    Map<String, dynamic> cadetData,
  ) async {
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final examService = ExamService();

      // 1. Fetch Attendance (already have service instance _attendanceService)
      final attendanceSnapshot = await _attendanceService
          .getCadetAttendance(uid)
          .first;
      final attendanceDocs = attendanceSnapshot.docs;
      final totalAtt = attendanceDocs.length;
      final presentAtt = attendanceDocs
          .where(
            (d) => (d.data() as Map<String, dynamic>)['status'] == 'Present',
          )
          .length;
      final absentAtt = attendanceDocs
          .where(
            (d) => (d.data() as Map<String, dynamic>)['status'] == 'Absent',
          )
          .length;
      final percentage = totalAtt > 0
          ? ((presentAtt / totalAtt) * 100).toStringAsFixed(1)
          : "0.0";

      final attendanceStats = {
        'total': totalAtt,
        'present': presentAtt,
        'absent': absentAtt,
        'percentage': percentage,
      };

      // 2. Fetch Exam Results
      final resultSnapshot = await examService.getCadetExamResults(uid).first;
      final examResults = resultSnapshot.docs
          .map(
            (d) =>
                ExamResultModel.fromMap(d.data() as Map<String, dynamic>, d.id),
          )
          .toList();

      // 3. Fetch All Exams
      final examsSnapshot = await examService
          .getOfficerExams(cadetData['organizationId'] ?? '')
          .first;
      final allExams = examsSnapshot.docs
          .map((d) => ExamModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();

      if (mounted) Navigator.pop(context); // Close loading

      await _pdfService.generateIndividualCadetReport(
        cadet: cadetData,
        attendanceStats: attendanceStats,
        examResults: examResults,
        allExams: allExams,
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error generating report: $e")));
      }
    }
  }
}
