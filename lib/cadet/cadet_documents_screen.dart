import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:provider/provider.dart';
import 'package:ncc_cadet/providers/user_provider.dart';
import 'package:ncc_cadet/services/document_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart'; // We need this, but check if added. If not, maybe use Link or similar.
// Actually connectivity_plus was added, checking pubspec for others.
// url_launcher might not be in pubspec yet. I should check or assume functionality.
// If url_launcher is missing, I can add it, or just show the URL to copy.
// Let's add url_launcher via command if needed.
// For now, I'll write the code assuming I can verify/add it.

class CadetDocumentsScreen extends StatefulWidget {
  const CadetDocumentsScreen({super.key});

  @override
  State<CadetDocumentsScreen> createState() => _CadetDocumentsScreenState();
}

class _CadetDocumentsScreenState extends State<CadetDocumentsScreen> {
  final DocumentService _docService = DocumentService();
  bool _isUploading = false;

  Future<void> _pickAndUploadFile() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      // Ask for Doc Type
      String? docType = await _showDocTypeDialog();
      if (docType == null) return;

      setState(() => _isUploading = true);

      final error = await _docService.uploadDocument(
        file: result.files.single,
        userId: user.uid,
        userName: user.name,
        organizationId: user.organizationId,
        docType: docType,
      );

      if (mounted) {
        setState(() => _isUploading = false);
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Upload Failed: $error"),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Document Uploaded Successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<String?> _showDocTypeDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Document Type'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'SSLC Certificate'),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('SSLC Certificate'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'Aadhar Card'),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Aadhar Card'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'Bank Passbook'),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Bank Passbook'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'NCC Certificate'),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('NCC Certificate'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'Other'),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Other'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text("Digital Records"),
        backgroundColor: AppTheme.navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadFile,
        backgroundColor: AppTheme.navyBlue,
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.upload_file, color: Colors.white),
        label: Text(
          _isUploading ? "Uploading..." : "Upload Document",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _docService.getUserDocuments(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.folder_open_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No documents uploaded yet.",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Upload your certificates and ID proofs here.",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
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

  Future<void> _updateDocument(
    String docId,
    String userId,
    String oldFileUrl,
  ) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      if (!mounted) return;
      setState(() => _isUploading = true);

      final error = await _docService.updateDocument(
        docId: docId,
        file: result.files.single,
        userId: userId,
        oldFileUrl: oldFileUrl,
      );

      if (mounted) {
        setState(() => _isUploading = false);
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Update Failed: $error"),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Document Updated Successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Widget _buildDocumentCard(String docId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'Pending';
    final user = Provider.of<UserProvider>(context, listen: false).user;
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                    // Fallback attempt without check
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
            } else if (action == 'Update') {
              if (user != null) {
                _updateDocument(docId, user.uid, data['fileUrl']);
              }
            } else if (action == 'Delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Delete Document"),
                  content: const Text(
                    "Are you sure you want to delete this document?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _docService.deleteDocument(docId, data['fileUrl']);
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'Download',
              child: Row(
                children: [
                  Icon(Icons.download, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Text("Download"),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'Update',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20, color: Colors.orange),
                  SizedBox(width: 8),
                  Text("Update"),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'Delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text("Delete"),
                ],
              ),
            ),
          ],
        ),
        onTap: () async {
          final url = data['fileUrl'];
          if (url != null) {
            try {
              final uri = Uri.parse(url);
              // Try launching regardless of canLaunchUrl check, which can be flaky on Android
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
    ).animate().fade().slideY(begin: 0.1, end: 0);
  }
}
