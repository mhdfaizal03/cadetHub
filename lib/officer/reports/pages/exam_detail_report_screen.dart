import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/exam_model.dart';
import 'package:ncc_cadet/models/exam_result_model.dart';
import 'package:ncc_cadet/services/exam_service.dart';
import 'package:ncc_cadet/services/pdf_generator_service.dart';
import 'package:ncc_cadet/utils/theme.dart';

class ExamDetailReportScreen extends StatefulWidget {
  final ExamModel exam;
  final String officerName; // For PDF report signature/context

  const ExamDetailReportScreen({
    super.key,
    required this.exam,
    this.officerName = "Officer",
  });

  @override
  State<ExamDetailReportScreen> createState() => _ExamDetailReportScreenState();
}

class _ExamDetailReportScreenState extends State<ExamDetailReportScreen> {
  final ExamService _examService = ExamService();
  final PdfGeneratorService _pdfService = PdfGeneratorService();

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exam Header Data
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
                    widget.exam.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navyBlue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("Type: ${widget.exam.type}"),
                  Text(
                    "Date: ${widget.exam.startDate} - ${widget.exam.endDate}",
                  ),
                  Text("Place: ${widget.exam.place ?? 'N/A'}"),
                  Text("Target: ${widget.exam.targetYear}"),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Results List Stream
            StreamBuilder<QuerySnapshot>(
              stream: _examService.getExamResults(widget.exam.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final results = snapshot.data!.docs.map((doc) {
                  return ExamResultModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  );
                }).toList();

                final passed = results.where((r) => r.status == 'Pass').length;
                final total = results.length;
                final passPerc = total == 0 ? 0.0 : (passed / total) * 100;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ...

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
                          _statItem("Passed", "$passed", color: Colors.green),
                          _statItem(
                            "Failed",
                            "${total - passed}",
                            color: Colors.orange,
                          ),
                          _statItem(
                            "Pass Rate",
                            "${passPerc.toStringAsFixed(1)}%",
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
                        label: const Text("Download Result Sheet"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.navyBlue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Downloading...")),
                          );
                          await _pdfService.generateExamResultListPDF(
                            exam: widget.exam,
                            results: results,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Results",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (results.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text("No results published yet."),
                        ),
                      ),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final result = results[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              result.cadetName.isEmpty
                                  ? "Cadet ${result.cadetId}"
                                  : result.cadetName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text("Marks: ${result.marks ?? 'N/A'}"),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: result.status == 'Pass'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                result.status,
                                style: TextStyle(
                                  color: result.status == 'Pass'
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
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
