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
  final PdfGeneratorService _pdfService = PdfGeneratorService();

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedYear = 'All'; // Default filter

  // Helper to pick date range
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
        // Manageable years filter logic
        // If restricted, _selectedYear must be within manageableYears or 'All' (if implied)
        // For simplicity, let's just let StreamBuilder handle permissions, but UI filtering:

        List<String> yearOptions = ['All', '1st Year', '2nd Year', '3rd Year'];
        if (manageableYears != null) {
          // If restricted, only show allowed years
          yearOptions = manageableYears;
          if (!yearOptions.contains(_selectedYear)) {
            _selectedYear = yearOptions.first;
          }
        }

        return Scaffold(
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
              "Attendance Report",
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: "Download Report",
                onPressed: () {
                  // Trigger download
                  // We need the data first. This is slightly tricky with Streams.
                  // Ideally we refactor to not nest streams this deeply or use a Provider.
                  // For now, I'll show a SnackBar guiding user to button in body?
                  // Or better, let's move the logic to body or use a scoped builder variable?
                  // I'll add a FAB for downloading which is inside the context of data if possible,
                  // OR I'll make the download button actually just trigger a function that refetches or uses state?
                  // Streams doesn't persist state easily.
                  // I will put a "Download PDF" button inside the builder.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please use the Download button below"),
                    ),
                  );
                },
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _authService.getCadetsStream(
              officer.organizationId,
              years: manageableYears,
            ),
            builder: (context, cadetSnapshot) {
              if (!cadetSnapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final cadets = cadetSnapshot.data!.docs;

              return StreamBuilder<QuerySnapshot>(
                stream: _attendanceService.getOrganizationAttendance(
                  officer.organizationId,
                ),
                builder: (context, attendanceSnapshot) {
                  if (!attendanceSnapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final attendance = attendanceSnapshot.data!.docs;

                  return StreamBuilder<QuerySnapshot>(
                    stream: _paradeService.getParadesStream(
                      officer.organizationId,
                    ),
                    builder: (context, paradeSnapshot) {
                      if (!paradeSnapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
                      final parades = paradeSnapshot.data!.docs;

                      return _buildReportBody(
                        officer,
                        manageableYears,
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
          ),
        );
      },
    );
  }

  Widget _buildReportBody(
    UserModel officer,
    List<String>? manageableYears,
    List<QueryDocumentSnapshot> allCadets,
    List<QueryDocumentSnapshot> allAttendance,
    List<QueryDocumentSnapshot> allParades,
    List<String> yearOptions,
  ) {
    // ---- FILTERING LOGIC ----

    // 1. Filter Cadets by Year (if selected)
    final filteredCadets = (_selectedYear == 'All' && manageableYears == null)
        ? allCadets // All allowed if no restriction
        : allCadets.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['year'] == _selectedYear ||
                (manageableYears != null &&
                    manageableYears.contains(data['year']) &&
                    _selectedYear == 'All');
          }).toList(); // If All selected but restricted, shows all manageable

    final targetCadetIds = filteredCadets.map((e) => e.id).toSet();

    // 2. Filter Parades by Date Range
    List<QueryDocumentSnapshot> filteredParades = allParades.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final dateStr = data['date'] as String;
      final date = DateTime.parse(dateStr);

      bool inRange = true;
      if (_startDate != null) inRange = inRange && !date.isBefore(_startDate!);
      if (_endDate != null)
        inRange =
            inRange &&
            !date.isAfter(
              _endDate!.add(const Duration(days: 1)),
            ); // Inclusive end

      return inRange;
    }).toList();

    // Sort parades desc
    filteredParades.sort(
      (a, b) => (b.data() as Map)['date'].compareTo((a.data() as Map)['date']),
    );

    // 3. Filter Attendance by Cadet IDs AND Parades
    final targetParadeIds = filteredParades.map((e) => e.id).toSet();
    final filteredAttendance = allAttendance.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return targetCadetIds.contains(data['cadetId']) &&
          targetParadeIds.contains(data['paradeId']);
    }).toList();

    // ---- STATS -----
    final totalRecords = filteredAttendance.length;
    final presentCount = filteredAttendance
        .where((d) => (d.data() as Map)['status'] == 'Present')
        .length;
    final absentCount = filteredAttendance
        .where((d) => (d.data() as Map)['status'] == 'Absent')
        .length;
    final excusedCount = filteredAttendance
        .where((d) => (d.data() as Map)['status'] == 'Excused')
        .length;
    final avgAttendance = totalRecords == 0
        ? 0.0
        : (presentCount / totalRecords);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: yearOptions.contains(_selectedYear)
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

          // Summary
          _buildUnitSummaryCard(avgAttendance),
          const SizedBox(height: 20),
          _buildBreakdownRow(presentCount, absentCount, excusedCount),
          const SizedBox(height: 20),

          // Download Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.file_download),
              label: const Text("Download PDF Report"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navyBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                // Generate PDF
                await _pdfService.generateAttendancePDF(
                  attendanceRecords: filteredAttendance,
                  parades: filteredParades,
                  title: "Attendance Report - $_selectedYear",
                  dateRange: _startDate == null
                      ? "All Dates"
                      : "${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}",
                  unitSummary:
                      "Avg: ${(avgAttendance * 100).toStringAsFixed(1)}% | Present: $presentCount | Absent: $absentCount",
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // List
          Text(
            "Parades (${filteredParades.length})",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          _buildParadeList(filteredParades, filteredAttendance),
        ],
      ),
    );
  }

  // Reused UI components (simplified)
  Widget _buildUnitSummaryCard(double percentage) {
    final percString = "${(percentage * 100).toStringAsFixed(1)}%";
    return Container(
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
                "Average Attendance",
                style: TextStyle(color: Colors.grey),
              ),
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
          CircularProgressIndicator(
            value: percentage,
            color: AppTheme.accentBlue,
          ), // Simplified
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(int present, int absent, int excused) {
    return Row(
      children: [
        Expanded(child: _statCard("Present", "$present", Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _statCard("Absent", "$absent", Colors.red)),
        const SizedBox(width: 12),
        Expanded(child: _statCard("Excused", "$excused", Colors.orange)),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
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

  Widget _buildParadeList(
    List<QueryDocumentSnapshot> parades,
    List<QueryDocumentSnapshot> attendance,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: parades.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) {
        final p = parades[index].data() as Map<String, dynamic>;
        final pid = parades[index].id;
        final date = p['date'];
        final records = attendance
            .where((d) => (d.data() as Map)['paradeId'] == pid)
            .toList();
        final present = records
            .where((d) => (d.data() as Map)['status'] == 'Present')
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
            title: Text(p['name'] ?? 'Parade'),
            subtitle: Text(date),
            trailing: Text(
              perc,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
