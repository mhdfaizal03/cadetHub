import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/parade_model.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/officer/add_parade.dart';
import 'package:ncc_cadet/officer/mark_attendance_screen.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/services/parade_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:ncc_cadet/utils/access_control.dart';
import 'package:intl/intl.dart';

class ParadeListScreen extends StatefulWidget {
  const ParadeListScreen({super.key});

  @override
  State<ParadeListScreen> createState() => _ParadeListScreenState();
}

class _ParadeListScreenState extends State<ParadeListScreen> {
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

        // Determine manageable years
        final manageableYears = getManageableYears(officer);
        final bool isRestricted = manageableYears != null;
        final bool singleYearView = isRestricted && manageableYears.length == 1;
        final bool canManage = officer.rank != 'Under Officer';

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
                "Manage Parades",
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
              backgroundColor: AppTheme.navyBlue,
              elevation: 0,
              foregroundColor: Colors.white,
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
              stream: ParadeService().getParadesStream(officer.organizationId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint("Error fetching parades: ${snapshot.error}");
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

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

                final allParades = snapshot.data!.docs
                    .map((doc) {
                      return ParadeModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      );
                    })
                    .where((p) {
                      if (manageableYears == null) return true;
                      return manageableYears.contains(p.targetYear);
                    })
                    .toList();

                if (singleYearView) {
                  return _buildParadeList(
                    allParades,
                    manageableYears.first,
                    canManage,
                  );
                }

                return TabBarView(
                  children: [
                    _buildParadeList(allParades, "All", canManage),
                    _buildParadeList(allParades, "1st Year", canManage),
                    _buildParadeList(allParades, "2nd Year", canManage),
                    _buildParadeList(allParades, "3rd Year", canManage),
                  ],
                );
              },
            ),
            floatingActionButton: canManage
                ? FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddEditParadeScreen(),
                        ),
                      );
                    },
                    backgroundColor: AppTheme.accentBlue,
                    child: const Icon(Icons.add, color: AppTheme.white),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildParadeList(
    List<ParadeModel> allParades,
    String year,
    bool canManage,
  ) {
    // strict filtering logic:
    // If year is "All" -> show everything
    // Else -> show parades where targetYear matches year
    final filteredParades = year == "All"
        ? allParades
        : allParades.where((p) => p.targetYear == year).toList();

    if (filteredParades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "No Parades for $year",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredParades.length,
      itemBuilder: (context, index) {
        return _buildParadeCard(context, filteredParades[index], canManage);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No Parades Scheduled",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildParadeCard(
    BuildContext context,
    ParadeModel parade,
    bool canManage,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navyBlue.withOpacity(0.05),
            blurRadius: 8,
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
                      parade.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
                        parade.targetYear,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (canManage)
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text("Edit"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Delete", style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditParadeScreen(parade: parade),
                        ),
                      );
                    } else if (value == 'delete') {
                      _confirmDelete(context, parade);
                    }
                  },
                ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                "${DateFormat('MMM d, yyyy').format(DateTime.parse(parade.date))} at ${parade.time}",
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                parade.location,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MarkAttendanceScreen(parade: parade),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text("Mark Attendance"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentBlue,
                side: const BorderSide(color: AppTheme.accentBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ParadeModel parade) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Parade"),
        content: const Text("Are you sure you want to delete this parade?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ParadeService().deleteParade(parade.id);
    }
  }
}
