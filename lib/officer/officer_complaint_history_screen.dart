import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/complaint_model.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/services/complaint_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:ncc_cadet/utils/access_control.dart';
import 'package:intl/intl.dart';

class OfficerComplaintHistoryScreen extends StatefulWidget {
  const OfficerComplaintHistoryScreen({super.key});

  @override
  State<OfficerComplaintHistoryScreen> createState() =>
      _OfficerComplaintHistoryScreenState();
}

class _OfficerComplaintHistoryScreenState
    extends State<OfficerComplaintHistoryScreen> {
  final AuthService _authService = AuthService();
  final ComplaintService _complaintService = ComplaintService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Complaint History",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.navyBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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

              final validCadetIds = cadetSnapshot.data!.docs
                  .map((doc) => doc.id)
                  .toSet();

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

                  // Filter: Only Resolved/Dismissed AND Only from valid Cadets
                  final filteredComplaints = allComplaints.where((c) {
                    final isHistory =
                        c.status == 'Resolved' || c.status == 'Dismissed';
                    final isManageable = validCadetIds.contains(c.cadetId);
                    return isHistory && isManageable;
                  }).toList();

                  if (filteredComplaints.isEmpty) {
                    return _buildEmptyState(message: "No history found");
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredComplaints.length,
                    itemBuilder: (context, index) {
                      final complaint = filteredComplaints[index];
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
                                  color: Colors.grey, // Dimmed for history
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                complaint.description,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                DateFormat(
                                  'MMM d, yyyy • h:mm a',
                                ).format(complaint.createdAt),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
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
          const Icon(Icons.history, size: 64, color: Colors.grey),
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
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
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
