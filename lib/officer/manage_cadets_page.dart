import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/utils/access_control.dart';
import 'package:flutter/material.dart';
import 'package:ncc_cadet/officer/addedit_cadet_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/officer/officer_cadet_records_screen.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/utils/theme.dart';

class ManageCadetsPage extends StatefulWidget {
  const ManageCadetsPage({super.key});

  @override
  State<ManageCadetsPage> createState() => _ManageCadetsPageState();
}

class _ManageCadetsPageState extends State<ManageCadetsPage> {
  final AuthService _authService = AuthService();
  String _searchQuery = "";

  // ... imports

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _authService.getUserProfile(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          // We need to wait for user profile before building Scaffold because of TabController length
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = userSnapshot.data;
        if (user == null) {
          return const Scaffold(body: Center(child: Text("Profile error")));
        }

        // Determine if restricted
        final manageableYears = getManageableYears(user);
        final bool isRestricted = manageableYears != null;
        final bool singleYearView = isRestricted && manageableYears.length == 1;

        return DefaultTabController(
          length: singleYearView ? 1 : 4,
          child: Scaffold(
            backgroundColor: const Color(0xFFF9F9F9),
            appBar: AppBar(
              foregroundColor: Colors.white,
              backgroundColor: AppTheme.navyBlue,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_left,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text("Manage Cadets"),
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
              stream: _authService.getCadetsStream(
                user.organizationId,
                years: manageableYears,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var allDocs = snapshot.data!.docs;

                if (singleYearView) {
                  return _buildCadetList(allDocs, manageableYears.first, user);
                }

                return TabBarView(
                  children: [
                    _buildCadetList(allDocs, "All", user),
                    _buildCadetList(allDocs, "1st Year", user),
                    _buildCadetList(allDocs, "2nd Year", user),
                    _buildCadetList(allDocs, "3rd Year", user),
                  ],
                );
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                // Navigate to add/edit page with null data (Add mode)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditCadetPage(),
                  ),
                );
              },
              backgroundColor: AppTheme.navyBlue,
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCadetList(
    List<QueryDocumentSnapshot> docs,
    String year,
    UserModel user,
  ) {
    // 1. Year Filtering
    var filteredDocs = year == "All"
        ? docs
        : docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['year'] == year;
          }).toList();

    // 2. Local Search Filtering
    if (_searchQuery.isNotEmpty) {
      filteredDocs = filteredDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().toLowerCase();
        final id = (data['cadetId'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase()) ||
            id.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return Column(
      children: [
        // Search Section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: "Search cadets by name or ID...",
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue),
              ),
            ),
          ),
        ),

        // Counts
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                "Total Cadets ($year): ${filteredDocs.length}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // List
        Expanded(
          child: filteredDocs.isEmpty
              ? Center(child: Text("No $year cadets found"))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final uid = doc.id;

                    return _buildCadetCard(uid, data, context, user.rank);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCadetCard(
    String uid,
    Map<String, dynamic> data,
    BuildContext context,
    String currentUserRank,
  ) {
    final name = data['name'] ?? 'Unknown';
    // ... (rest of variable declarations)
    final id = data['cadetId'] ?? 'N/A';
    final rank = data['rank'] ?? 'Cadet';
    final status = data['status'] == 1
        ? 'Active'
        : (data['status'] == 0 ? 'Pending' : 'Inactive');
    final isActive = data['status'] == 1;
    final year = data['year'] ?? '1st Year';

    return Container(
      // ... (container decoration)
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ... (name, id, badges)
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Text(
                  id,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildBadge(rank, Colors.grey.shade100, Colors.black54),
                    _buildBadge(
                      status,
                      isActive ? Colors.green.shade50 : Colors.orange.shade50,
                      isActive ? Colors.green : Colors.orange,
                    ),
                    _buildBadge(
                      year,
                      Colors.blue.shade50,
                      Colors.blue.shade700,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.folder_shared_outlined,
                  size: 20,
                  color: Colors.blue,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OfficerCadetRecordsScreen(
                        cadetId: uid,
                        cadetName: name,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: Colors.grey,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddEditCadetPage(cadetData: {'uid': uid, ...data}),
                    ),
                  );
                },
              ),
              if (currentUserRank !=
                  'Under Officer') // Prevent UO from deleting
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _confirmDelete(uid, name),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _confirmDelete(String uid, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Cadet"),
        content: Text(
          "Are you sure you want to delete $name? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.deleteUser(uid);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
