import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/exam_model.dart';
import 'package:ncc_cadet/models/camp_model.dart';
import 'package:ncc_cadet/models/exam_result_model.dart';

class PdfGeneratorService {
  Future<void> generateAttendancePDF({
    required List<QueryDocumentSnapshot> attendanceRecords,
    required List<QueryDocumentSnapshot> parades,
    required String title,
    required String dateRange,
    required String unitSummary,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.nunitoExtraLight();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(title, dateRange, font),
            pw.SizedBox(height: 20),
            pw.Text(unitSummary, style: pw.TextStyle(font: font, fontSize: 14)),
            pw.SizedBox(height: 20),
            _buildAttendanceTable(parades, attendanceRecords, font),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> generateExamPDF({
    required List<ExamModel> exams,
    required String title,
    required String subtitle,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoExtraLight();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(title, subtitle, font),
            pw.SizedBox(height: 20),
            _buildExamTable(exams, font),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> generateCampPDF({
    required List<CampModel> camps,
    required String title,
    required String subtitle,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoExtraLight();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(title, subtitle, font),
            pw.SizedBox(height: 20),
            _buildCampTable(camps, font),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> generateParadeListPDF({
    required List<QueryDocumentSnapshot> parades,
    required List<QueryDocumentSnapshot> attendanceRecords,
    required String title,
    required String subtitle,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoExtraLight();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(title, subtitle, font),
            pw.SizedBox(height: 20),
            _buildAttendanceTable(parades, attendanceRecords, font),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildHeader(String title, String subtitle, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: font,
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          subtitle,
          style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey),
        ),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildAttendanceTable(
    List<QueryDocumentSnapshot> parades,
    List<QueryDocumentSnapshot> attendanceRecords,
    pw.Font font,
  ) {
    // Simplify: List Parades and Summary stats per parade?
    // Or list Cadets?
    // For a generic report passed like this, let's list Parades with attendance %

    return pw.Table.fromTextArray(
      context: null,
      headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(font: font),
      headers: <String>[
        'Date',
        'Parade Name',
        'Present',
        'Absent',
        'Excused',
        'Total',
      ],
      data: parades.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final paradeId = doc.id;
        final date = data['date'] ?? '';
        final name = data['name'] ?? 'Parade';

        final records = attendanceRecords
            .where(
              (r) => (r.data() as Map<String, dynamic>)['paradeId'] == paradeId,
            )
            .toList();
        final present = records
            .where(
              (r) => (r.data() as Map<String, dynamic>)['status'] == 'Present',
            )
            .length;
        final absent = records
            .where(
              (r) => (r.data() as Map<String, dynamic>)['status'] == 'Absent',
            )
            .length;
        final excused = records
            .where(
              (r) => (r.data() as Map<String, dynamic>)['status'] == 'Excused',
            )
            .length;
        final total = records.length;

        return [
          date,
          name,
          present.toString(),
          absent.toString(),
          excused.toString(),
          total.toString(),
        ];
      }).toList(),
    );
  }

  pw.Widget _buildExamTable(List<ExamModel> exams, pw.Font font) {
    return pw.Table.fromTextArray(
      context: null,
      headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(font: font),
      headers: <String>[
        'Title',
        'Target Year',
        'Start Date',
        'End Date',
        'Place',
      ],
      data: exams.map((exam) {
        return [
          exam.title,
          exam.targetYear,
          exam.startDate,
          exam.endDate,
          exam.place,
        ];
      }).toList(),
    );
  }

  pw.Widget _buildCampTable(List<CampModel> camps, pw.Font font) {
    return pw.Table.fromTextArray(
      context: null,
      headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(font: font),
      headers: <String>[
        'Camp Name',
        'Location',
        'Target Year',
        'Start Date',
        'End Date',
      ],
      data: camps.map((camp) {
        return [
          camp.name,
          camp.location,
          camp.targetYear,
          camp.startDate,
          camp.endDate,
        ];
      }).toList(),
    );
  }

  Future<void> generateIndividualCadetReport({
    required Map<String, dynamic> cadet,
    required Map<String, dynamic> attendanceStats,
    required List<ExamResultModel> examResults,
    required List<ExamModel> allExams, // To link examId to Title
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoExtraLight();
    final boldFont = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "NCC Cadet Report",
                    style: pw.TextStyle(font: boldFont, fontSize: 24),
                  ),
                  pw.Text(
                    DateFormat('MMM d, yyyy').format(DateTime.now()),
                    style: pw.TextStyle(font: font, fontSize: 14),
                  ),
                ],
              ),
            ),
            pw.Divider(),
            pw.SizedBox(height: 20),

            // Profile Section
            pw.Text(
              "Cadet Profile",
              style: pw.TextStyle(font: boldFont, fontSize: 18),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildProfileRow(
                    "Name",
                    cadet['name'] ?? 'N/A',
                    font,
                    boldFont,
                  ),
                  _buildProfileRow(
                    "Cadet ID",
                    cadet['cadetId'] ?? 'N/A',
                    font,
                    boldFont,
                  ),
                  _buildProfileRow(
                    "Rank",
                    cadet['rank'] ?? 'Cadet',
                    font,
                    boldFont,
                  ),
                  _buildProfileRow(
                    "Year",
                    cadet['year'] ?? 'N/A',
                    font,
                    boldFont,
                  ),
                  _buildProfileRow(
                    "Mobile",
                    cadet['mobile'] ?? 'N/A',
                    font,
                    boldFont,
                  ),
                  _buildProfileRow(
                    "Email",
                    cadet['email'] ?? 'N/A',
                    font,
                    boldFont,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Attendance Section
            pw.Text(
              "Attendance Summary",
              style: pw.TextStyle(font: boldFont, fontSize: 18),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBox(
                    "Total Parades",
                    "${attendanceStats['total']}",
                    font,
                    boldFont,
                  ),
                  _buildStatBox(
                    "Present",
                    "${attendanceStats['present']}",
                    font,
                    boldFont,
                  ),
                  _buildStatBox(
                    "Absent",
                    "${attendanceStats['absent']}",
                    font,
                    boldFont,
                  ),
                  _buildStatBox(
                    "Percentage",
                    "${attendanceStats['percentage']}%",
                    font,
                    boldFont,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Exam Results Section
            pw.Text(
              "Exam Results",
              style: pw.TextStyle(font: boldFont, fontSize: 18),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(font: boldFont),
              cellStyle: pw.TextStyle(font: font),
              headers: ['Exam Title', 'Date', 'Status', 'Verdict'],
              data: examResults.map((result) {
                final exam = allExams.firstWhere(
                  (e) => e.id == result.examId,
                  orElse: () => ExamModel(
                    id: '',
                    title: 'Unknown',
                    description: '',
                    startDate: '',
                    endDate: '',
                    startTime: '',
                    endTime: '',
                    place: '',
                    organizationId: '',
                    type: '',
                    targetYear: '',
                    createdAt: DateTime.now(),
                  ),
                );
                return [
                  exam.title,
                  exam.startDate,
                  result.status,
                  result.status == 'Pass'
                      ? 'PASSED'
                      : result.status == 'Fail'
                      ? 'FAILED'
                      : 'ABSENT',
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 50),
            pw.Divider(),
            pw.Text(
              "Authorized Signature",
              style: pw.TextStyle(font: font, fontSize: 12),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> generateExamResultListPDF({
    required ExamModel exam,
    required List<ExamResultModel> results,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoExtraLight();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader("Exam Result Sheet", exam.title, font),
            pw.SizedBox(height: 10),
            pw.Text(
              "Date: ${exam.startDate} - ${exam.endDate}",
              style: pw.TextStyle(font: font),
            ),
            pw.Text(
              "Type: ${exam.type} | Target: ${exam.targetYear}",
              style: pw.TextStyle(font: font),
            ),
            pw.SizedBox(height: 20),
            _buildResultTable(results, font),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildResultTable(List<ExamResultModel> results, pw.Font font) {
    return pw.Table.fromTextArray(
      context: null,
      headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(font: font),
      headers: <String>['Cadet Name', 'Cadet ID', 'Status', 'Marks', 'Result'],
      data: results.map((r) {
        return [
          r.cadetName.isEmpty ? 'N/A' : r.cadetName,
          r.cadetId,
          r.status,
          r.marks?.toString() ?? 'N/A',
          r.status == 'Pass' ? "PASS" : "FAIL",
        ];
      }).toList(),
    );
  }

  pw.Widget _buildProfileRow(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text("$label:", style: pw.TextStyle(font: boldFont)),
          ),
          pw.Text(value, style: pw.TextStyle(font: font)),
        ],
      ),
    );
  }

  pw.Widget _buildStatBox(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 16)),
        pw.Text(
          label,
          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey),
        ),
      ],
    );
  }
}
