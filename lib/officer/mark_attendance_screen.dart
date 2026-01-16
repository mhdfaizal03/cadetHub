import 'package:flutter/material.dart';
import 'package:ncc_cadet/models/attendance_model.dart';
import 'package:ncc_cadet/models/parade_model.dart';
import 'package:ncc_cadet/services/attendance_service.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/utils/theme.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final ParadeModel parade;
  const MarkAttendanceScreen({super.key, required this.parade});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final AuthService _authService = AuthService();
  final AttendanceService _attendanceService = AttendanceService();

  List<Map<String, dynamic>> _cadetsToCheck = [];
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
      // 1. Get all cadets in the organization
      final cadetsSnapshot = await _authService
          .getCadetsStream(widget.parade.organizationId)
          .first;
      final cadets = cadetsSnapshot.docs
          .where((doc) {
            if (widget.parade.targetYear == 'All') return true;
            final data = doc.data() as Map<String, dynamic>;
            return data['year'] == widget.parade.targetYear;
          })
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'uid': doc.id,
              'name': data['name'] ?? 'Unknown',
              'id': data['cadetId'] ?? 'N/A',
              'status': 'Absent', // Default
              'recordId': '', // To track if we are updating
            };
          })
          .toList();

      // 2. Get existing attendance for this parade
      final attendanceSnapshot = await _attendanceService
          .getAttendanceForParade(widget.parade.id)
          .first;

      for (var recordDoc in attendanceSnapshot.docs) {
        final data = recordDoc.data() as Map<String, dynamic>;
        final cadetId = data['cadetId'];
        final status = data['status'];

        final cadetIndex = cadets.indexWhere((c) => c['uid'] == cadetId);
        if (cadetIndex != -1) {
          cadets[cadetIndex]['status'] = status;
          cadets[cadetIndex]['recordId'] = recordDoc.id;
        }
      }

      _cadetsToCheck = cadets;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading data: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);
    try {
      final records = _cadetsToCheck.map((cadet) {
        return AttendanceModel(
          id: cadet['recordId'], // Empty if new
          paradeId: widget.parade.id,
          cadetId: cadet['uid'],
          cadetName: cadet['name'],
          status: cadet['status'],
          date: widget.parade.date,
          organizationId: widget.parade.organizationId,
          createdAt: DateTime.now(),
        );
      }).toList();

      await _attendanceService.markBatchAttendance(records);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Attendance Saved Successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              "Mark Attendance",
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
            Text(
              widget.parade.name,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveAttendance,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accentBlue,
                    ),
                  )
                : Text(
                    "Save",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.accentBlue,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentBlue),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _cadetsToCheck.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final cadet = _cadetsToCheck[index];
                final isPresent = cadet['status'] == 'Present';
                final isExcused = cadet['status'] == 'Excused';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey.shade100,
                        child: Text(
                          cadet['name'][0],
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cadet['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              cadet['id'],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _buildStatusButton("P", isPresent, Colors.green, () {
                            setState(() => cadet['status'] = 'Present');
                          }),
                          const SizedBox(width: 8),
                          _buildStatusButton(
                            "A",
                            !isPresent && !isExcused,
                            Colors.red,
                            () {
                              setState(() => cadet['status'] = 'Absent');
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildStatusButton("E", isExcused, Colors.orange, () {
                            setState(() => cadet['status'] = 'Excused');
                          }),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusButton(
    String label,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
          shape: BoxShape.circle,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
