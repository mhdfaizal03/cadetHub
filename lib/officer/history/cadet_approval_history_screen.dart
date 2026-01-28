import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:ncc_cadet/utils/access_control.dart';

class CadetApprovalHistoryScreen extends StatefulWidget {
  const CadetApprovalHistoryScreen({super.key});

  @override
  State<CadetApprovalHistoryScreen> createState() =>
      _CadetApprovalHistoryScreenState();
}

class _CadetApprovalHistoryScreenState
    extends State<CadetApprovalHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: AuthService().getUserProfile(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.lightGrey,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.accentBlue),
            ),
          );
        }

        final officer = userSnapshot.data;
        if (officer == null) {
          return const Scaffold(
            body: Center(child: Text("Error fetching officer profile")),
          );
        }

        final manageableYears = getManageableYears(officer);
        final bool isRestricted = manageableYears != null;
        final bool singleYearView = isRestricted && manageableYears.length == 1;

        return DefaultTabController(
          length: singleYearView ? 1 : 4,
          child: Scaffold(
            backgroundColor: AppTheme.lightGrey,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_left,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                "Cadet Approval History",
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
              backgroundColor: AppTheme.navyBlue,
              elevation: 0,
              bottom: singleYearView
                  ? null
                  : TabBar(
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
            body: StreamBuilder<QuerySnapshot>(
              stream: AuthService().getProcessedCadetsStream(
                officer.organizationId,
                years: manageableYears,
              ),
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

                final allDocs = snapshot.data!.docs;

                // Sort filtering client side if needed, but stream already did basic query
                // We might want to sort by some timestamp if available, but users don't have createdAt usually available directly in the model list easily
                // without fetching full logic. Firestore default order is doc ID if not specified.
                // But for history it's fine.

                if (singleYearView) {
                  return _buildCadetList(allDocs, manageableYears.first);
                }

                return TabBarView(
                  children: [
                    _buildCadetList(allDocs, "All"),
                    _buildCadetList(allDocs, "1st Year"),
                    _buildCadetList(allDocs, "2nd Year"),
                    _buildCadetList(allDocs, "3rd Year"),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No History Available",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCadetList(List<QueryDocumentSnapshot> allDocs, String year) {
    // Filter docs based on year
    final filteredDocs = year == "All"
        ? allDocs
        : allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['year'] == year;
          }).toList();

    if (filteredDocs.isEmpty) {
      return Center(
        child: Text(
          "No history for $year",
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredDocs.length,
      itemBuilder: (context, index) {
        final doc = filteredDocs[index];
        final data = doc.data() as Map<String, dynamic>;
        return _buildHistoryCard(doc.id, data);
      },
    );
  }

  Widget _buildHistoryCard(String docId, Map<String, dynamic> data) {
    final status = data['status'];
    final bool isApproved = status == 1;
    final statusColor = isApproved ? Colors.green : Colors.red;
    final statusText = isApproved ? "Approved" : "Rejected";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navyBlue.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'Unknown Cadet',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Cadet ID: ${data['cadetId'] ?? 'N/A'}",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    data['year'] ?? '1st Year',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
          if (isApproved) ...[
            const SizedBox(width: 8),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'reject',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text("Reject Cadet", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'reject') {
                  _confirmReject(context, docId, data['name']);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmReject(
    BuildContext context,
    String docId,
    String? name,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reject Cadet"),
        content: Text(
          "Are you sure you want to reject ${name ?? 'this cadet'}?\n\nThey will be moved to the Rejected list.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Reject", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AuthService().updateCadetStatus(docId, -1);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cadet rejected successfully"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }
}
