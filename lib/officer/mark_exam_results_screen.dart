import 'package:flutter/material.dart';
import 'package:ncc_cadet/models/exam_model.dart';
import 'package:ncc_cadet/models/exam_result_model.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/services/exam_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:ncc_cadet/utils/access_control.dart';

class MarkExamResultsScreen extends StatefulWidget {
  final ExamModel exam;
  const MarkExamResultsScreen({super.key, required this.exam});

  @override
  State<MarkExamResultsScreen> createState() => _MarkExamResultsScreenState();
}

class _MarkExamResultsScreenState extends State<MarkExamResultsScreen> {
  final AuthService _authService = AuthService();
  final ExamService _examService = ExamService();

  List<Map<String, dynamic>> _cadetList = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = await _authService.getUserProfile();
      if (currentUser == null) return;

      // 1. Fetch Cadets
      final manageableYears = getManageableYears(currentUser);
      final cadetsSnapshot = await _authService
          .getCadetsStream(widget.exam.organizationId, years: manageableYears)
          .first;

      // Filter by Exam Target Year
      final eligibleCadets = cadetsSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final year = data['year'];
        if (widget.exam.targetYear == 'All') return true;
        return year == widget.exam.targetYear;
      }).toList();

      // 2. Fetch Existing Results
      final resultsSnapshot = await _examService
          .getExamResults(widget.exam.id)
          .first;
      final existingResults = resultsSnapshot.docs.map((doc) {
        return ExamResultModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      // 3. Merge
      _cadetList = eligibleCadets.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final cadetId = doc.id;

        // Find existing result
        final result = existingResults.firstWhere(
          (r) => r.cadetId == cadetId,
          orElse: () => ExamResultModel(
            id: '',
            examId: widget.exam.id,
            cadetId: cadetId,
            cadetName: data['name'] ?? '',
            status:
                'Absent', // Default to Absent or maybe 'Pending'? Let's perform initial load as 'Absent' matches logic
            remarks: '',
            createdAt: DateTime.now(),
          ),
        );

        return {
          'cadetId': cadetId,
          'name': data['name'] ?? 'Unknown',
          'year': data['year'] ?? '',
          'resultId': result.id.isEmpty
              ? DateTime.now().millisecondsSinceEpoch.toString() + cadetId
              : result.id, // Generate temp ID if new
          'status': result.id.isEmpty
              ? null
              : result.status, // Null means not marked yet
          'remarks': result.remarks,
        };
      }).toList();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveResults() async {
    setState(() => _isSaving = true);
    try {
      for (var item in _cadetList) {
        // Only save if status is set
        if (item['status'] != null) {
          final result = ExamResultModel(
            id: item['resultId'],
            examId: widget.exam.id,
            cadetId: item['cadetId'],
            cadetName: item['name'],
            status: item['status'],
            remarks: item['remarks'] ?? '',
            createdAt: DateTime.now(),
          );
          await _examService.markExamResult(result);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Results Saved"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error saving: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text("Mark Exam Results"),
        backgroundColor: AppTheme.navyBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveResults,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cadetList.length,
              itemBuilder: (context, index) {
                final item = _cadetList[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                item['year'],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Pass/Fail Toggles
                        ToggleButtons(
                          constraints: const BoxConstraints(
                            minHeight: 36,
                            minWidth: 48,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          isSelected: [
                            item['status'] == 'Pass',
                            item['status'] == 'Fail',
                            item['status'] ==
                                'Absent', // or just Not Marked? default null
                          ],
                          onPressed: (idx) {
                            setState(() {
                              if (idx == 0) item['status'] = 'Pass';
                              if (idx == 1) item['status'] = 'Fail';
                              if (idx == 2) item['status'] = 'Absent';
                            });
                          },
                          selectedColor: Colors.white,
                          fillColor: Colors
                              .transparent, // Handled by selected logic if needed, but standard toggle buttons handle fill
                          // Customizing fill
                          key: ValueKey(item['cadetId']),
                          children: [
                            Container(
                              color: item['status'] == 'Pass'
                                  ? Colors.green
                                  : null,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Pass",
                                style: TextStyle(
                                  color: item['status'] == 'Pass'
                                      ? Colors.white
                                      : Colors.green,
                                ),
                              ),
                            ),
                            Container(
                              color: item['status'] == 'Fail'
                                  ? Colors.red
                                  : null,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Fail",
                                style: TextStyle(
                                  color: item['status'] == 'Fail'
                                      ? Colors.white
                                      : Colors.red,
                                ),
                              ),
                            ),
                            Container(
                              color: item['status'] == 'Absent'
                                  ? Colors.orange
                                  : null,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Abs",
                                style: TextStyle(
                                  color: item['status'] == 'Absent'
                                      ? Colors.white
                                      : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
