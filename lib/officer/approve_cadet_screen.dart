import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/utils/access_control.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/utils/theme.dart';

class ApproveCadetPage extends StatefulWidget {
  const ApproveCadetPage({super.key});

  @override
  State<ApproveCadetPage> createState() => _ApproveCadetPageState();
}

class _ApproveCadetPageState extends State<ApproveCadetPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_left, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("Approve Cadets"),
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
          // Fetch current officer's profile to get organizationId
          future: AuthService().getUserProfile(),
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

            final manageableYears = getManageableYears(officer);
            final bool canViewAll = manageableYears == null;

            return StreamBuilder<QuerySnapshot>(
              // Use the organizationId to filter pending cadets
              stream: AuthService().pendingCadets(
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No pending requests for ${officer.organizationId}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allDocs = snapshot.data!.docs;

                if (!canViewAll) {
                  // For restricted users, we might still want tabs if they manage multiple years (e.g. 3rd Year UO manages 1st & 2nd)
                  // Or just show "All" which is implicitly filtered?
                  // Providing tabs for manageable years would be nice, but "All" is sufficient for now given the limitation of tabs hardcoded.
                  // Actually, hardcoded tabs might show empty lists for years they can't manage, which is fine.
                  // But previously we returned just one list.
                  // Let's stick to showing tabs, they will just be empty for years not in manageableYears.
                  // However, if we want to show ONLY manageable years, that requires major UI refactor of the TabController length.
                  // Let's keep the tabs but relying on the stream data which is already filtered.
                  // But `_buildCadetList` does local filtering too.
                  return TabBarView(
                    children: [
                      _buildCadetList(allDocs, "All"),
                      _buildCadetList(allDocs, "1st Year"),
                      _buildCadetList(allDocs, "2nd Year"),
                      _buildCadetList(allDocs, "3rd Year"),
                    ],
                  );
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
            );
          },
        ),
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
          "No pending requests for $year",
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
        return _buildPendingCadetCard(context, doc.id, data);
      },
    );
  }

  Widget _buildPendingCadetCard(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        data['year'] ?? '1st Year',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Text(
                  "Pending",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => AuthService().updateCadetStatus(docId, 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    "Approve",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => AuthService().updateCadetStatus(docId, -1),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF9A9A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    "Reject",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
