import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/services/document_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class OfficerCadetRecordsScreen extends StatefulWidget {
  final String cadetId;
  final String cadetName;

  const OfficerCadetRecordsScreen({
    super.key,
    required this.cadetId,
    required this.cadetName,
  });

  @override
  State<OfficerCadetRecordsScreen> createState() =>
      _OfficerCadetRecordsScreenState();
}

class _OfficerCadetRecordsScreenState extends State<OfficerCadetRecordsScreen> {
  final DocumentService _docService = DocumentService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: Text("${widget.cadetName}'s Records"),
        backgroundColor: AppTheme.navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _docService.getUserDocuments(widget.cadetId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No documents found for this cadet."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildDocumentCard(doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(String docId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'Pending';
    Color statusColor = Colors.orange;
    if (status == 'Approved') statusColor = Colors.green;
    if (status == 'Rejected') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.description_outlined,
            color: AppTheme.navyBlue,
          ),
        ),
        title: Text(
          data['docType'] ?? 'Document',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['fileName'] ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  "Status: ",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'Approve') {
              _docService.updateDocumentStatus(docId, 'Approved');
            } else if (action == 'Reject') {
              _docService.updateDocumentStatus(docId, 'Rejected');
            } else if (action == 'Delete') {
              _confirmDelete(docId, data['fileUrl']);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Approve', child: Text("Approve")),
            const PopupMenuItem(value: 'Reject', child: Text("Reject")),
            const PopupMenuItem(
              value: 'Delete',
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        onTap: () async {
          final url = Uri.parse(data['fileUrl']);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Could not open file")),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(String docId, String fileUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Record"),
        content: const Text("Are you sure you want to delete this record?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _docService.deleteDocument(docId, fileUrl);
    }
  }
}
