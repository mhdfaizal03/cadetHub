import 'package:flutter/material.dart';
import 'package:ncc_cadet/models/exam_model.dart';
import 'package:ncc_cadet/services/exam_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:ncc_cadet/providers/user_provider.dart';
import 'package:intl/intl.dart';

class AddExamPage extends StatefulWidget {
  const AddExamPage({super.key});

  @override
  State<AddExamPage> createState() => _AddExamPageState();
}

class _AddExamPageState extends State<AddExamPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _placeController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  String _targetYear = '2nd Year'; // Default
  String _examType = 'B Certificate'; // Default based on year usually
  bool _isLoading = false;

  void _updateExamType(String? year) {
    setState(() {
      _targetYear = year!;
      if (_targetYear == '2nd Year') {
        _examType = 'B Certificate';
      } else if (_targetYear == '3rd Year') {
        _examType = 'C Certificate';
      } else {
        _examType = 'Internal';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Schedule New Exam"),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Exam Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navyBlue,
                ),
              ),
              const SizedBox(height: 20),

              // Target Year Dropdown
              DropdownButtonFormField<String>(
                value: _targetYear,
                decoration: _inputDecoration("Target Year"),
                items: const [
                  DropdownMenuItem(value: '2nd Year', child: Text("2nd Year")),
                  DropdownMenuItem(value: '3rd Year', child: Text("3rd Year")),
                  DropdownMenuItem(value: 'All', child: Text("All Cadets")),
                ],
                onChanged: _updateExamType,
              ),
              const SizedBox(height: 16),

              // Exam Type
              DropdownButtonFormField<String>(
                value: _examType,
                decoration: _inputDecoration("Exam Type"),
                items: const [
                  DropdownMenuItem(
                    value: 'B Certificate',
                    child: Text("B Certificate"),
                  ),
                  DropdownMenuItem(
                    value: 'C Certificate',
                    child: Text("C Certificate"),
                  ),
                  DropdownMenuItem(
                    value: 'Internal',
                    child: Text("Internal/Other"),
                  ),
                ],
                onChanged: (val) => setState(() => _examType = val!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration(
                  "Exam Title",
                  hint: "e.g., Drill Test 1",
                ),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _placeController,
                decoration: _inputDecoration(
                  "Exam Place",
                  hint: "e.g., Parade Ground",
                  icon: Icons.location_on_outlined,
                ),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                decoration: _inputDecoration(
                  "Description",
                  hint: "Topics covered...",
                ).copyWith(alignLabelWithHint: true),
                maxLines: 3,
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      decoration: _inputDecoration(
                        "Start Date",
                        icon: Icons.calendar_today,
                      ),
                      readOnly: true,
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          _startDateController.text = DateFormat(
                            'MMM d, yyyy',
                          ).format(picked);
                        }
                      },
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _endDateController,
                      decoration: _inputDecoration(
                        "End Date",
                        icon: Icons.calendar_today,
                      ),
                      readOnly: true,
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          _endDateController.text = DateFormat(
                            'MMM d, yyyy',
                          ).format(picked);
                        }
                      },
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startTimeController,
                      decoration: _inputDecoration(
                        "Start Time",
                        icon: Icons.access_time,
                      ),
                      readOnly: true,
                      onTap: () async {
                        TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null && mounted) {
                          _startTimeController.text = picked.format(context);
                        }
                      },
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _endTimeController,
                      decoration: _inputDecoration(
                        "End Time",
                        icon: Icons.access_time_filled,
                      ),
                      readOnly: true,
                      onTap: () async {
                        TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null && mounted) {
                          _endTimeController.text = picked.format(context);
                        }
                      },
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitExam,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.navyBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Schedule Exam & Notify",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.navyBlue),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  Future<void> _submitExam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Provider.of<UserProvider>(context, listen: false).user!;
      final newExam = ExamModel(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        startDate: _startDateController.text,
        endDate: _endDateController.text, // Added
        startTime: _startTimeController.text,
        endTime: _endTimeController.text,
        place: _placeController.text.trim(),
        type: _examType,
        targetYear: _targetYear,
        organizationId: user.organizationId,
        createdAt: DateTime.now(),
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      await ExamService().createExam(newExam);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Exam Scheduled Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
