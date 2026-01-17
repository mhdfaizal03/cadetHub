import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/exam_model.dart';
import 'package:ncc_cadet/services/exam_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:ncc_cadet/utils/access_control.dart';
import 'package:provider/provider.dart';
import 'package:ncc_cadet/providers/user_provider.dart';
import 'package:ncc_cadet/officer/add_exam_page.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OfficerExamListScreen extends StatefulWidget {
  const OfficerExamListScreen({super.key});

  @override
  State<OfficerExamListScreen> createState() => _OfficerExamListScreenState();
}

class _OfficerExamListScreenState extends State<OfficerExamListScreen> {
  final ExamService _examService = ExamService();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text("Manage Exams"),
        backgroundColor: AppTheme.navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExamPage()),
          );
        },
        backgroundColor: AppTheme.navyBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Create Exam", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _examService.getOfficerExams(user.organizationId),
        builder: (context, snapshot) {
          final manageableYears = getManageableYears(user);
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No exams created yet",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final exam = ExamModel.fromMap(data, doc.id);

              if (manageableYears != null &&
                  !manageableYears.contains(exam.targetYear)) {
                return const SizedBox.shrink();
              }

              return _buildExamCard(exam);
            },
          );
        },
      ),
    );
  }

  Widget _buildExamCard(ExamModel exam) {
    Color typeColor = Colors.blue;
    if (exam.type.contains('B')) typeColor = Colors.orange;
    if (exam.type.contains('C')) typeColor = Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exam.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.navyBlue,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
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
            const SizedBox(height: 8),
            Text(
              exam.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  exam.date,
                  style: TextStyle(color: Colors.grey[800], fontSize: 13),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  exam.time,
                  style: TextStyle(color: Colors.grey[800], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.group_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  "Target: ${exam.targetYear}",
                  style: TextStyle(color: Colors.grey[800], fontSize: 13),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(exam),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fade().slideY(begin: 0.1, end: 0);
  }

  void _confirmDelete(ExamModel exam) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Exam"),
        content: Text("Are you sure you want to delete '${exam.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _examService.deleteExam(exam.id);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
