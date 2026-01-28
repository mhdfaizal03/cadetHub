import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/exam_model.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/services/exam_service.dart';
import 'package:ncc_cadet/services/pdf_generator_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:ncc_cadet/utils/access_control.dart';

class OfficerExamReportPage extends StatefulWidget {
  const OfficerExamReportPage({super.key});

  @override
  State<OfficerExamReportPage> createState() => _OfficerExamReportPageState();
}

class _OfficerExamReportPageState extends State<OfficerExamReportPage> {
  final AuthService _authService = AuthService();
  final ExamService _examService = ExamService();
  final PdfGeneratorService _pdfService = PdfGeneratorService();

  String _selectedYear = 'All';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _authService.getUserProfile(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final officer = userSnapshot.data;
        if (officer == null) {
          return const Scaffold(body: Center(child: Text("Error")));
        }

        final manageableYears = getManageableYears(officer);
        List<String> yearOptions = ['All', '1st Year', '2nd Year', '3rd Year'];
        if (manageableYears != null) {
          yearOptions = manageableYears;
          if (!yearOptions.contains(_selectedYear)) {
            _selectedYear = yearOptions.first;
          }
        }

        return Scaffold(
          backgroundColor: AppTheme.lightGrey,
          appBar: AppBar(
            title: const Text("Exam Report"),
            backgroundColor: AppTheme.navyBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_left),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _examService.getOfficerExams(officer.organizationId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allExams = snapshot.data!.docs.map((doc) {
                return ExamModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
              }).toList();

              // Filter
              final filteredExams = allExams.where((exam) {
                if (_selectedYear == 'All') return true;
                return exam.targetYear == _selectedYear;
              }).toList();

              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Filter
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: yearOptions.contains(_selectedYear)
                            ? _selectedYear
                            : yearOptions.first,
                        decoration: const InputDecoration(
                          labelText: "Target Year",
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
                    const SizedBox(height: 20),

                    // Download
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.file_download),
                        label: const Text("Download PDF List"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.navyBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          await _pdfService.generateExamPDF(
                            exams: filteredExams,
                            title: "Exam Schedule Report",
                            subtitle:
                                "Target Year: $_selectedYear | Total Exams: ${filteredExams.length}",
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // List
                    Expanded(
                      child: ListView.separated(
                        itemCount: filteredExams.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, index) {
                          final exam = filteredExams[index];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              title: Text(
                                exam.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "${exam.startDate} - ${exam.endDate}",
                              ),
                              trailing: Chip(
                                label: Text(
                                  exam.type,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: AppTheme.navyBlue.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
