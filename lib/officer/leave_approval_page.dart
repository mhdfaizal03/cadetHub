import 'package:flutter/material.dart';
import 'package:ncc_cadet/models/leave_model.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/services/leave_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/utils/theme.dart';

class ApproveLeavePage extends StatefulWidget {
  const ApproveLeavePage({super.key});

  @override
  State<ApproveLeavePage> createState() => _ApproveLeavePageState();
}

class _ApproveLeavePageState extends State<ApproveLeavePage> {
  final LeaveService _leaveService = LeaveService();
  final AuthService _authService = AuthService();

  Future<void> _updateStatus(String id, String status, {String? reason}) async {
    try {
      await _leaveService.updateLeaveStatus(
        id,
        status,
        rejectionReason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Leave $status"),
            backgroundColor: status == 'Approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showLeaveDetails(BuildContext context, LeaveModel leave) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(leave.cadetName),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<UserModel?>(
                  future: _authService.getUserData(leave.cadetId),
                  builder: (context, snapshot) {
                    String displayId = "Loading...";
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData && snapshot.data != null) {
                        displayId = snapshot.data!.roleId;
                      } else {
                        displayId = "Unknown";
                      }
                    }
                    return _buildInfoRow(
                      Icons.badge_outlined,
                      "Cadet ID",
                      displayId,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.calendar_today,
                  "Duration",
                  "${leave.startDate} to ${leave.endDate}",
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.info_outline, "Reason", leave.reason),
                const SizedBox(height: 20),
                if (leave.status == 'Pending') ...[
                  const Divider(),
                  const Text(
                    "Action",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  // We can't easily put logic inside AlertDialog simply without StatefulBuilder if we need UI updates
                  // But for just rejection reason input, we can show ANOTHER dialog or navigate.
                  // Let's keep it simple: "Reject" button opens a rejection reason input dialog.
                ],
                if (leave.status == 'Rejected' && leave.rejectionReason != null)
                  _buildInfoRow(
                    Icons.cancel_outlined,
                    "Rejection Reason",
                    leave.rejectionReason!,
                    color: Colors.red,
                  ),
              ],
            ),
          ),
          actions: [
            if (leave.status == 'Pending') ...[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showRejectionDialog(context, leave.id);
                },
                child: const Text(
                  "Reject",
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _updateStatus(leave.id, 'Approved');
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                ),
                child: const Text(
                  "Approve",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ] else
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
          ],
        );
      },
    );
  }

  void _showRejectionDialog(BuildContext context, String leaveId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reject Leave"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Please provide a reason for rejection:"),
              const SizedBox(height: 10),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: "Reason (Optional)",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _updateStatus(
                  leaveId,
                  'Rejected',
                  reason: reasonController.text.trim(),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                "Reject Request",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color ?? Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppTheme.lightGrey,
        appBar: AppBar(
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_left,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Approve Leave",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppTheme.navyBlue,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            labelColor: AppTheme.accentBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.accentBlue,
            tabs: const [
              Tab(text: "All"),
              Tab(text: "1st Year"),
              Tab(text: "2nd Year"),
              Tab(text: "3rd Year"),
            ],
          ),
        ),
        body: FutureBuilder<UserModel?>(
          future: _authService.getUserProfile(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.accentBlue),
              );
            }

            final officer = userSnapshot.data;
            if (officer == null) {
              return const Center(
                child: Text("Error fetching officer profile"),
              );
            }

            return StreamBuilder<QuerySnapshot>(
              stream: _leaveService.getPendingLeaves(officer.organizationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentBlue,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final leaves = snapshot.data!.docs.map((doc) {
                  return LeaveModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  );
                }).toList();

                return TabBarView(
                  children: [
                    _buildLeaveList(leaves, "All"),
                    _buildLeaveList(leaves, "1st Year"),
                    _buildLeaveList(leaves, "2nd Year"),
                    _buildLeaveList(leaves, "3rd Year"),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No Pending Leave Requests",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveList(List<LeaveModel> allLeaves, String year) {
    // If year is "All", show all. usage of trim() is important if spacing differs.
    // Ensure we handle 'Unknown' or missing years gracefully if needed,
    // but for now strict filtering is fine as per request.
    final filteredLeaves = year == "All"
        ? allLeaves
        : allLeaves.where((l) => l.cadetYear == year).toList();

    if (filteredLeaves.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              "No Requests for $year",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredLeaves.length,
      itemBuilder: (context, index) {
        final leave = filteredLeaves[index];
        return InkWell(
          onTap: () => _showLeaveDetails(context, leave),
          child: LeaveRequestCard(
            name: leave.cadetName,
            id: leave.cadetId,
            dates: "${leave.startDate} → ${leave.endDate}",
            reason: leave.reason,
            status: leave.status,
            // Remove direct buttons, handle in dialog
            onApprove: null,
            onReject: null,
          ),
        );
      },
    );
  }
}

// ---------------- Leave Request Card ----------------

class LeaveRequestCard extends StatelessWidget {
  final String name, id, dates, reason, status;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const LeaveRequestCard({
    super.key,
    required this.name,
    required this.id,
    required this.dates,
    required this.reason,
    required this.status,
    this.onApprove,
    this.onReject,
  });

  Color get statusColor {
    switch (status) {
      case "Approved":
        return Colors.green;
      case "Rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navyBlue.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              BadgeWidget(label: status, color: statusColor),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            "Cadet ID: $id",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),

          const SizedBox(height: 12),

          Row(
            children: const [
              Icon(Icons.date_range, size: 16, color: Colors.grey),
              SizedBox(width: 6),
              Text(
                "Leave Duration",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(dates, style: const TextStyle(fontSize: 14)),

          const SizedBox(height: 10),

          const Text(
            "Reason",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reason,
            style: const TextStyle(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          if (status == "Pending" &&
              (onApprove != null || onReject != null)) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppTheme.accentBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Approve"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Reject",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------- Badge Widget ----------------

class BadgeWidget extends StatelessWidget {
  final String label;
  final Color color;

  const BadgeWidget({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
