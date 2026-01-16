import 'package:ncc_cadet/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:ncc_cadet/officer/addedit_cadet_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/services/auth_service.dart';

class ManageCadetsPage extends StatefulWidget {
  const ManageCadetsPage({super.key});

  @override
  State<ManageCadetsPage> createState() => _ManageCadetsPageState();
}

class _ManageCadetsPageState extends State<ManageCadetsPage> {
  final AuthService _authService = AuthService();
  String _searchQuery = "";
  String _selectedYear = "All"; // Filter state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Manage Cadets",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: FutureBuilder<UserModel?>(
        future: _authService.getUserProfile(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final officer = userSnapshot.data;
          if (officer == null) {
            return const Center(child: Text("Officer profile not found"));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _authService.getCadetsStream(officer.organizationId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("No cadets found in this unit."),
                );
              }

              var docs = snapshot.data!.docs;

              // Year Filtering
              if (_selectedYear != "All") {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['year'] == _selectedYear;
                }).toList();
              }

              // Local Search Filtering
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final id = (data['cadetId'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery.toLowerCase()) ||
                      id.contains(_searchQuery.toLowerCase());
                }).toList();
              }

              return Column(
                children: [
                  // 1. Filter Chips (Year)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: ["All", "1st Year", "2nd Year", "3rd Year"].map(
                        (year) {
                          final isSelected = _selectedYear == year;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(year),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() => _selectedYear = year);
                              },
                              backgroundColor: Colors.white,
                              selectedColor: Colors.blue.shade100,
                              checkmarkColor: Colors.blue,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ),

                  // 2. Search Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Search cadets by name or ID...",
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
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

                  // 2. Counts
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Text(
                          "Total Cadets: ${docs.length}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final uid = doc.id;

                        return _buildCadetCard(uid, data, context);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add/edit page with null data (Add mode)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditCadetPage()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildCadetCard(
    String uid,
    Map<String, dynamic> data,
    BuildContext context,
  ) {
    final name = data['name'] ?? 'Unknown';
    final id = data['cadetId'] ?? 'N/A';
    final rank = data['rank'] ?? 'Cadet';
    final status = data['status'] == 1
        ? 'Active'
        : (data['status'] == 0 ? 'Pending' : 'Inactive');
    final isActive = data['status'] == 1;

    return Container(
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
                Row(
                  children: [
                    _buildBadge(rank, Colors.grey.shade100, Colors.black54),
                    const SizedBox(width: 8),
                    _buildBadge(
                      status,
                      isActive ? Colors.green.shade50 : Colors.orange.shade50,
                      isActive ? Colors.green : Colors.orange,
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
