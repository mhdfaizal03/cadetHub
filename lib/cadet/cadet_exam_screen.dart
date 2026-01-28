import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ncc_cadet/models/exam_model.dart';
import 'package:ncc_cadet/services/exam_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:ncc_cadet/providers/user_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CadetExamScreen extends StatelessWidget {
  const CadetExamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.lightGrey,
        appBar: AppBar(
          title: const Text("My Exams"),
          backgroundColor: AppTheme.navyBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_left),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            indicatorColor: AppTheme.gold,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Upcoming"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: ExamService().getExamsStream(
            user.organizationId,
            year: user.year,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No exams found"));
            }

            final allExams = snapshot.data!.docs.map((doc) {
              return ExamModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
            }).toList();

            // Nested Stream for Results
            return StreamBuilder<QuerySnapshot>(
              stream: ExamService().getCadetExamResults(user.uid),
              builder: (context, resultSnapshot) {
                // Map examId -> result status
                Map<String, String> examResults = {};
                if (resultSnapshot.hasData) {
                  for (var doc in resultSnapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    examResults[data['examId']] = data['status'] ?? '';
                  }
                }

                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);

                List<ExamModel> upcoming = [];
                List<ExamModel> history = [];

                for (var exam in allExams) {
                  bool isHistory = false;
                  try {
                    DateTime examEnd = DateFormat(
                      'MMM d, yyyy',
                    ).parse(exam.endDate);
                    if (examEnd.isBefore(today)) {
                      isHistory = true;
                    }
                  } catch (e) {}

                  if (isHistory) {
                    history.add(exam);
                  } else {
                    upcoming.add(exam);
                  }
                }

                return TabBarView(
                  children: [
                    _buildExamList(upcoming, "No upcoming exams", examResults),
                    _buildExamList(history, "No exam history", examResults),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildExamList(
    List<ExamModel> exams,
    String emptyMsg,
    Map<String, String> results,
  ) {
    if (exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              emptyMsg,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exams.length,
      itemBuilder: (context, index) =>
          _buildExamCard(exams[index], results[exams[index].id]),
    );
  }

  Widget _buildExamCard(ExamModel exam, String? resultStatus) {
    Color typeColor = Colors.blue;
    if (exam.type.contains('B')) typeColor = Colors.orange;
    if (exam.type.contains('C')) typeColor = Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.5)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.navyBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      color: AppTheme.navyBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              exam.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppTheme.navyBlue,
                              ),
                            ),
                            if (resultStatus != null && resultStatus.isNotEmpty)
                              _buildResultBadge(resultStatus),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            exam.type,
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Text(
                exam.description,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.calendar_today,
                    "${exam.startDate} - ${exam.endDate}",
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.access_time,
                    "${exam.startTime} - ${exam.endTime}",
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoChip(Icons.location_on_outlined, exam.place),
            ],
          ),
        ),
      ),
    ).animate().fade().slideY(begin: 0.1, end: 0);
  }

  Widget _buildResultBadge(String status) {
    Color color = Colors.grey;
    if (status == 'Pass') color = Colors.green;
    if (status == 'Fail') color = Colors.red;
    if (status == 'Absent') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
