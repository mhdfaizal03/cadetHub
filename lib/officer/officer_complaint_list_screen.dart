import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/complaint_model.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/services/complaint_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:ncc_cadet/utils/access_control.dart';
import 'package:intl/intl.dart';
import 'package:ncc_cadet/officer/officer_complaint_history_screen.dart';

class OfficerComplaintListScreen extends StatefulWidget {
  const OfficerComplaintListScreen({super.key});

  @override
  State<OfficerComplaintListScreen> createState() =>
      _OfficerComplaintListScreenState();
}

class _OfficerComplaintListScreenState
    extends State<OfficerComplaintListScreen> {
  final AuthService _authService = AuthService();
  final ComplaintService _complaintService = ComplaintService();

  Future<void> _updateStatus(String id, String status) async {
    try {
      await _complaintService.updateComplaintStatus(id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Complaint marked as $status"),
            backgroundColor: status == 'Resolved' ? Colors.green : Colors.grey,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: AppTheme.white),
        title: const Text(
          "Manage Complaints",
          style: TextStyle(color: AppTheme.white),
        ),
        backgroundColor: AppTheme.navyBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left, color: AppTheme.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppTheme.white),
            tooltip: "Complaint History",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OfficerComplaintHistoryScreen(),
                ),
              );
            },
          ),
        ],
        centerTitle: true,
      ),
      body: FutureBuilder<UserModel?>(
        future: _authService.getUserProfile(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final officer = userSnapshot.data;
          if (officer == null) {
            return const Center(child: Text("Error fetching officer profile"));
          }

          final manageableYears = getManageableYears(officer);

          return StreamBuilder<QuerySnapshot>(
            stream: _authService.getCadetsStream(
              officer.organizationId,
              years: manageableYears,
            ),
            builder: (context, cadetSnapshot) {
              if (!cadetSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Create a set of valid Cadet IDs based on management permissions
              final validCadetIds = cadetSnapshot.data!.docs
                  .map((doc) => doc.id)
                  .toSet();
              // Also map cadetId to Year for display if needed? Not strictly needed if filters work.

              return StreamBuilder<QuerySnapshot>(
                stream: _complaintService.getOrganizationComplaints(
                  officer.organizationId,
                ),
                builder: (context, complaintSnapshot) {
                  if (complaintSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!complaintSnapshot.hasData ||
                      complaintSnapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  final allComplaints = complaintSnapshot.data!.docs.map((doc) {
                    return ComplaintModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );
                  }).toList();

                  // Filter: Only Pending AND Only from valid Cadets (manageable years)
                  final filteredComplaints = allComplaints.where((c) {
                    final isPending = c.status == 'Pending';
                    final isManageable = validCadetIds.contains(c.cadetId);
                    return isPending && isManageable;
                  }).toList();

                  if (filteredComplaints.isEmpty) {
                    return _buildEmptyState(message: "No pending complaints");
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredComplaints.length,
                    itemBuilder: (context, index) {
                      final complaint = filteredComplaints[index];
                      // Find cadet details for year display?
                      // We don't have year in ComplaintModel, could look up from cadet list if efficiency ok.
                      // For now, simple list.

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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Cadet: ${complaint.cadetName}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  _StatusBadge(status: complaint.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                complaint.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                complaint.description,
                                style: const TextStyle(color: Colors.black87),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat(
                                      'MMM d, yyyy • h:mm a',
                                    ).format(complaint.createdAt),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      TextButton(
                                        onPressed: () => _updateStatus(
                                          complaint.id,
                                          'Dismissed',
                                        ),
                                        child: const Text(
                                          "Dismiss",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () => _updateStatus(
                                          complaint.id,
                                          'Resolved',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        child: const Text(
                                          "Resolve",
                                          style: TextStyle(
                                            color: AppTheme.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({String message = "No complaints found"}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Resolved':
        color = Colors.green;
        break;
      case 'Dismissed':
        color = AppTheme.error;
        break;
      default:
        color = AppTheme.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
