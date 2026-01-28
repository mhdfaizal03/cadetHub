import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/exam_model.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/services/exam_service.dart';
import 'package:ncc_cadet/services/pdf_generator_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:ncc_cadet/utils/access_control.dart';
import 'package:ncc_cadet/officer/reports/pages/exam_detail_report_screen.dart';

class ExamReportView extends StatefulWidget {
  const ExamReportView({super.key});

  @override
  State<ExamReportView> createState() => _ExamReportViewState();
}

class _ExamReportViewState extends State<ExamReportView> {
  final AuthService _authService = AuthService();
  final ExamService _examService = ExamService();
  final PdfGeneratorService _pdfService = PdfGeneratorService();

  String _selectedYear = 'All';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _authService.getUserProfile(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final officer = userSnapshot.data!;

        final manageableYears = getManageableYears(officer);
        List<String> yearOptions = ['All', '1st Year', '2nd Year', '3rd Year'];
        if (manageableYears != null) {
          yearOptions = manageableYears;
          if (!yearOptions.contains(_selectedYear)) {
            _selectedYear = yearOptions.first;
          }
        }

        return StreamBuilder<QuerySnapshot>(
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

            final filteredExams = allExams.where((exam) {
              if (_selectedYear == 'All') return true;
              return exam.targetYear == _selectedYear;
            }).toList();

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
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
                      onChanged: (val) => setState(() => _selectedYear = val!),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.file_download),
                      label: const Text("Download Exam List"),
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
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${exam.startDate} - ${exam.endDate}"),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ExamDetailReportScreen(exam: exam),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.navyBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppTheme.navyBlue.withOpacity(
                                          0.2,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.edit_note,
                                          size: 16,
                                          color: AppTheme.navyBlue,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "View Details",
                                          style: TextStyle(
                                            color: AppTheme.navyBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  exam.type,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
        );
      },
    );
  }
}
