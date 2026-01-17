import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/complaint_model.dart';
import 'package:ncc_cadet/providers/user_provider.dart';
import 'package:ncc_cadet/services/complaint_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CadetComplaintScreen extends StatefulWidget {
  const CadetComplaintScreen({super.key});

  @override
  State<CadetComplaintScreen> createState() => _CadetComplaintScreenState();
}

class _CadetComplaintScreenState extends State<CadetComplaintScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _submitComplaint() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      if (user == null) return;

      final complaint = ComplaintModel(
        id: '',
        cadetId: user.uid,
        cadetName: user.name,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status: 'Pending',
        organizationId: user.organizationId,
        createdAt: DateTime.now(),
      );

      await ComplaintService().submitComplaint(complaint);

      _titleController.clear();
      _descriptionController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Complaint submitted successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
          context,
        ); // Close the BottomSheet or Dialog usually, but here we might just stay on screen
        // Better yet, just show success.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddComplaintDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "New Complaint",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  _submitComplaint();
                  Navigator.pop(context); // Close modal
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navyBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Submit",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User session error")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left, color: Colors.black),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          "Complaints",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddComplaintDialog,
        backgroundColor: AppTheme.navyBlue,
        icon: const Icon(Icons.add),
        label: const Text("New Complaint"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ComplaintService().getCadetComplaints(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.comment_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    "No complaints found.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final complaints = snapshot.data!.docs.map((doc) {
            return ComplaintModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              Color statusColor = Colors.orange;
              if (complaint.status == 'Resolved') statusColor = Colors.green;
              if (complaint.status == 'Dismissed') statusColor = Colors.red;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            complaint.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            complaint.status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      complaint.description,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat(
                        'MMM d, yyyy • h:mm a',
                      ).format(complaint.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
