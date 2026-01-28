import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';

import 'package:ncc_cadet/services/document_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class OfficerCadetRecordsScreen extends StatefulWidget {
  final String cadetId;
  final String cadetName;
  final String organizationId;

  const OfficerCadetRecordsScreen({
    super.key,
    required this.cadetId,
    required this.cadetName,
    required this.organizationId,
  });

  @override
  State<OfficerCadetRecordsScreen> createState() =>
      _OfficerCadetRecordsScreenState();
}

class _OfficerCadetRecordsScreenState extends State<OfficerCadetRecordsScreen> {
  final DocumentService _docService = DocumentService();

  // ... imports at top (add file_picker)
  // Inside State class:
  Future<void> _uploadDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      PlatformFile file = result.files.first;

      // Show dialog to select document type
      String? docType = await showDialog<String>(
        context: context,
        builder: (context) {
          String selectedType = 'Medical Report';
          // Officers might upload different types than cadets
          final types = [
            'SSLC Certificate',
            'Aadhar Card',
            'Bank Passbook',
            'PAN Card',
            'Medical Report',
            'Camp Certificate',
            'Merit Certificate',
            'Disciplinary Record',
            'Other',
          ];

          return AlertDialog(
            title: const Text("Select Document Type"),
            content: DropdownButtonFormField<String>(
              initialValue: selectedType,
              items: types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => selectedType = val!,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, selectedType),
                child: const Text("Upload"),
              ),
            ],
          );
        },
      );

      if (docType == null) return;

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Uploading document...")));
      }

      final error = await _docService.uploadDocument(
        file: file,
        userId: widget.cadetId,
        docType: docType,
        userName: widget.cadetName,
        organizationId: widget.organizationId,
      );

      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Document uploaded successfully")),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Upload failed: $error")));
        }
      }
    }
  }

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
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadDocument,
        backgroundColor: AppTheme.navyBlue,
        child: const Icon(Icons.upload_file, color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // ... rest of stream builder
        stream: _docService.getUserDocuments(widget.cadetId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No documents found for this cadet."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final data = snapshot.data![index];
              return _buildDocumentCard(data['id'], data);
            },
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(String docId, Map<String, dynamic> data) {
    final createdAt = data['created_at'];

    String dateStr = "";
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        dateStr = "${date.day}/${date.month}/${date.year}";
      } catch (e) {
        dateStr = "";
      }
    }

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
            if (dateStr.isNotEmpty)
              Text(
                "Uploaded: $dateStr",
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            if (action == 'Download') {
              final fileUrl = data['fileUrl'];
              if (fileUrl != null) {
                try {
                  // Get generated signed download URL
                  final downloadUrl = await _docService.getDownloadUrl(fileUrl);

                  final uri = Uri.parse(downloadUrl ?? fileUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (!await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    )) {
                      throw 'Could not launch URL';
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Could not download file: $e")),
                    );
                  }
                }
              }
            } else if (action == 'Delete') {
              _confirmDelete(docId, data['fileUrl']);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'Download',
              child: Text("Download", style: TextStyle(color: Colors.blue)),
            ),
            const PopupMenuItem(
              value: 'Delete',
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        onTap: () async {
          final url = data['fileUrl'];
          if (url != null) {
            try {
              final uri = Uri.parse(url);
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                throw 'Could not launch $url';
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Could not open file: $e")),
                );
              }
            }
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(String docId, String fileUrl) async {
    // ... delete logic
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
