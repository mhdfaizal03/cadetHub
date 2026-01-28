import 'package:flutter/material.dart';
import 'package:ncc_cadet/models/attendance_model.dart';
import 'package:ncc_cadet/models/camp_model.dart';
import 'package:ncc_cadet/services/attendance_service.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:ncc_cadet/utils/access_control.dart';

class MarkCampAttendanceScreen extends StatefulWidget {
  final CampModel camp;
  const MarkCampAttendanceScreen({super.key, required this.camp});

  @override
  State<MarkCampAttendanceScreen> createState() =>
      _MarkCampAttendanceScreenState();
}

class _MarkCampAttendanceScreenState extends State<MarkCampAttendanceScreen> {
  final AuthService _authService = AuthService();
  final AttendanceService _attendanceService = AttendanceService();

  List<Map<String, dynamic>> _allCadets = [];
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

      final manageableYears = getManageableYears(currentUser);
      final cadetsSnapshot = await _authService
          .getCadetsStream(widget.camp.organizationId, years: manageableYears)
          .first;

      final cadets = cadetsSnapshot.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final cadetYear = data['year'] ?? '';

            if (widget.camp.targetYear == 'All') return true;
            return cadetYear == widget.camp.targetYear;
          })
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'uid': doc.id,
              'name': data['name'] ?? 'Unknown',
              'id': data['cadetId'] ?? 'N/A',
              'year': data['year'] ?? '1st Year',
              'status': 'Absent', // Default
              'recordId': '',
            };
          })
          .toList();

      final attendanceSnapshot = await _attendanceService
          .getAttendanceForCamp(widget.camp.id)
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

      _allCadets = cadets;
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
      final records = _allCadets.map((cadet) {
        return AttendanceModel(
          id: cadet['recordId'],
          campId: widget.camp.id,
          paradeId: '', // Not applicable
          cadetId: cadet['uid'],
          cadetName: cadet['name'],
          status: cadet['status'],
          date: widget.camp.startDate, // Use Start Date as reference
          organizationId: widget.camp.organizationId,
          createdAt: DateTime.now(),
          type: 'Camp',
        );
      }).toList();

      await _attendanceService.markBatchAttendance(records);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Camp Attendance Saved"),
            backgroundColor: Colors.green,
          ),
        );
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
    if (widget.camp.targetYear != 'All') {
      return Scaffold(
        backgroundColor: AppTheme.lightGrey,
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accentBlue),
              )
            : _buildCadetList(_allCadets),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppTheme.lightGrey,
        appBar: _buildAppBar(withTabs: true),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accentBlue),
              )
            : TabBarView(
                children: [
                  _buildCadetList(_allCadets),
                  _buildCadetList(
                    _allCadets.where((c) => c['year'] == '1st Year').toList(),
                  ),
                  _buildCadetList(
                    _allCadets.where((c) => c['year'] == '2nd Year').toList(),
                  ),
                  _buildCadetList(
                    _allCadets.where((c) => c['year'] == '3rd Year').toList(),
                  ),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar({bool withTabs = false}) {
    return AppBar(
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(
          Icons.keyboard_arrow_left,
          color: AppTheme.navyBlue,
          size: 28,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        children: [
          const Text(
            "Mark Camp Attendance",
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
          Text(
            widget.camp.name,
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
      bottom: withTabs
          ? TabBar(
              labelColor: AppTheme.accentBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.accentBlue,
              isScrollable: true,
              tabs: const [
                Tab(text: "All"),
                Tab(text: "1st Year"),
                Tab(text: "2nd Year"),
                Tab(text: "3rd Year"),
              ],
            )
          : null,
    );
  }

  Widget _buildCadetList(List<Map<String, dynamic>> cadets) {
    if (cadets.isEmpty)
      return const Center(
        child: Text("No cadets found", style: TextStyle(color: Colors.grey)),
      );

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cadets.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final cadet = cadets[index];
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${cadet['id']} • ${cadet['year']}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
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
