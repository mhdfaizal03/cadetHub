import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/camp_model.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/officer/add_edit_camp_screen.dart';
import 'package:ncc_cadet/officer/camp_participants_screen.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/services/camp_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:ncc_cadet/utils/access_control.dart';
import 'package:intl/intl.dart';
import 'package:ncc_cadet/officer/history/camp_history_screen.dart';

class OfficerCampListScreen extends StatefulWidget {
  const OfficerCampListScreen({super.key});

  @override
  State<OfficerCampListScreen> createState() => _OfficerCampListScreenState();
}

class _OfficerCampListScreenState extends State<OfficerCampListScreen> {
  final AuthService _authService = AuthService();
  final CampService _campService = CampService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _authService.getUserProfile(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.lightGrey,
            body: Center(child: CircularProgressIndicator()),
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
        final bool canManage =
            officer.role == 'officer' || officer.rank == 'Senior Under Officer';

        return DefaultTabController(
          length: singleYearView ? 1 : 4,
          child: Scaffold(
            backgroundColor: AppTheme.lightGrey,
            appBar: AppBar(
              title: const Text(
                "Manage Camps",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: AppTheme.navyBlue,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.white),
                  tooltip: "Camp History",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CampHistoryScreen(),
                      ),
                    );
                  },
                ),
              ],
              leading: IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_left,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.maybePop(context),
              ),
              centerTitle: true,
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
              stream: _campService.getCamps(officer.organizationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final allCamps = snapshot.data!.docs
                    .map((doc) {
                      return CampModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      );
                    })
                    .where((camp) {
                      if (manageableYears != null &&
                          !manageableYears.contains(camp.targetYear)) {
                        return false;
                      }

                      // 2. Upcoming filter: EndDate >= Today
                      try {
                        final endDate = DateTime.parse(camp.endDate);
                        final normalizeEndDate = DateTime(
                          endDate.year,
                          endDate.month,
                          endDate.day,
                        );
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        return !normalizeEndDate.isBefore(
                          today,
                        ); // Show today or future
                      } catch (e) {
                        return true;
                      }
                    })
                    .toList();

                if (singleYearView) {
                  return _buildCampList(
                    allCamps,
                    manageableYears.first,
                    canManage,
                  );
                }

                return TabBarView(
                  children: [
                    _buildCampList(allCamps, "All", canManage),
                    _buildCampList(allCamps, "1st Year", canManage),
                    _buildCampList(allCamps, "2nd Year", canManage),
                    _buildCampList(allCamps, "3rd Year", canManage),
                  ],
                );
              },
            ),
            floatingActionButton: canManage
                ? FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddEditCampScreen(),
                        ),
                      );
                    },
                    backgroundColor: AppTheme.navyBlue,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      "Add Camp",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildCampList(List<CampModel> allCamps, String year, bool canManage) {
    final filteredCamps = year == "All"
        ? allCamps
        : allCamps.where((c) => c.targetYear == year).toList();

    if (filteredCamps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.terrain_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "No camps for $year",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredCamps.length,
      itemBuilder: (context, index) {
        final camp = filteredCamps[index];
        return _buildCampCard(camp, canManage);
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.terrain_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("No camps scheduled", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCampCard(CampModel camp, bool canManage) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              camp.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                camp.targetYear,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "${DateFormat('MMM d, yyyy').format(DateTime.parse(camp.startDate))} - ${DateFormat('MMM d, yyyy').format(DateTime.parse(camp.endDate))}",
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(camp.location),
              ],
            ),
          ],
        ),

        trailing: canManage
            ? PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'participants',
                    child: Row(
                      children: [
                        Icon(Icons.people_outline, size: 16),
                        SizedBox(width: 8),
                        Text("Participants"),
                      ],
                    ),
                  ),
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
                onSelected: (value) async {
                  if (value == 'participants') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CampParticipantsScreen(camp: camp),
                      ),
                    );
                  } else if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditCampScreen(camp: camp),
                      ),
                    );
                  } else if (value == 'delete') {
                    _confirmDelete(camp);
                  }
                },
              )
            : IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CampParticipantsScreen(camp: camp),
                    ),
                  );
                },
                icon: const Icon(Icons.people_outline),
                tooltip: "Participants",
              ),
      ),
    );
  }

  Future<void> _confirmDelete(CampModel camp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Camp"),
        content: const Text("Are you sure you want to delete this camp?"),
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
      await _campService.deleteCamp(camp.id);
    }
  }
}
