import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/camp_model.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/services/camp_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:ncc_cadet/utils/access_control.dart';
import 'package:ncc_cadet/officer/camp_participants_screen.dart';
import 'package:intl/intl.dart';

class CampHistoryScreen extends StatefulWidget {
  const CampHistoryScreen({super.key});

  @override
  State<CampHistoryScreen> createState() => _CampHistoryScreenState();
}

class _CampHistoryScreenState extends State<CampHistoryScreen> {
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

        final manageableYears = getManageableYears(officer);
        final bool isRestricted = manageableYears != null;
        final bool singleYearView = isRestricted && manageableYears.length == 1;
        // In history, maybe we don't need buttons to edit/manage, just view/participants?
        // Let's allow viewing participants.

        return DefaultTabController(
          length: singleYearView ? 1 : 4,
          child: Scaffold(
            backgroundColor: AppTheme.lightGrey,
            appBar: AppBar(
              title: const Text(
                "Camp History",
                style: TextStyle(color: Colors.white),
              ),
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

                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);

                final allCamps = snapshot.data!.docs
                    .map((doc) {
                      return CampModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      );
                    })
                    .where((camp) {
                      // 1. Manageable years
                      if (manageableYears != null &&
                          !manageableYears.contains(camp.targetYear)) {
                        return false;
                      }

                      // 2. History Filter: EndDate < Today
                      try {
                        final endDate = DateTime.parse(camp.endDate);
                        final normalizeEndDate = DateTime(
                          endDate.year,
                          endDate.month,
                          endDate.day,
                        );
                        return normalizeEndDate.isBefore(today);
                      } catch (e) {
                        return false;
                      }
                    })
                    .toList();

                // Sort by end date descending
                allCamps.sort((a, b) => b.endDate.compareTo(a.endDate));

                if (singleYearView) {
                  return _buildCampList(allCamps, manageableYears.first);
                }

                return TabBarView(
                  children: [
                    _buildCampList(allCamps, "All"),
                    _buildCampList(allCamps, "1st Year"),
                    _buildCampList(allCamps, "2nd Year"),
                    _buildCampList(allCamps, "3rd Year"),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCampList(List<CampModel> allCamps, String year) {
    final filteredCamps = year == "All"
        ? allCamps
        : allCamps.where((c) => c.targetYear == year).toList();

    if (filteredCamps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "No Camp History for $year",
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
        return _buildCampCard(camp);
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("No Camp History", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCampCard(CampModel camp) {
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                camp.targetYear,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
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
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),

        trailing: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CampParticipantsScreen(camp: camp),
              ),
            );
          },
          icon: const Icon(Icons.people_outline, color: Colors.grey),
          tooltip: "View Participants",
        ),
      ),
    );
  }
}
