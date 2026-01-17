import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ncc_cadet/models/leave_model.dart';
import 'package:ncc_cadet/services/leave_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:ncc_cadet/providers/user_provider.dart';

class CadetLeaveHistoryScreen extends StatelessWidget {
  const CadetLeaveHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text(
          "My Leave Requests",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text("User session error"))
          : StreamBuilder<QuerySnapshot>(
              stream: LeaveService().getCadetLeaves(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentBlue,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_edu,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No leave requests found",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final leaves = snapshot.data!.docs.map((doc) {
                  return LeaveModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  );
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: leaves.length,
                  itemBuilder: (context, index) {
                    return _buildLeaveCard(leaves[index]);
                  },
                );
              },
            ),
    );
  }

  Widget _buildLeaveCard(LeaveModel leave) {
    // Determine status color
    Color statusColor;
    IconData statusIcon;
    switch (leave.status) {
      case 'Approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status and Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(statusIcon, size: 20, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    leave.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Text(
                DateFormat('MMM d, yyyy').format(leave.createdAt),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const Divider(height: 24),

          // Dates
          Row(
            children: [
              const Icon(Icons.date_range, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                "${leave.startDate}  ➜  ${leave.endDate}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Reason
          const Text(
            "Reason:",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(leave.reason, style: const TextStyle(fontSize: 14)),

          // Rejection Reason (If Rejected)
          if (leave.status == 'Rejected' &&
              leave.rejectionReason != null &&
              leave.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, size: 16, color: Colors.red),
                      SizedBox(width: 6),
                      Text(
                        "Rejection Note",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    leave.rejectionReason!,
                    style: TextStyle(fontSize: 13, color: Colors.red.shade800),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
