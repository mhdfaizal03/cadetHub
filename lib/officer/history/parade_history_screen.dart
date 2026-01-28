import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/parade_model.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/services/parade_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:ncc_cadet/utils/access_control.dart';
import 'package:intl/intl.dart';

class ParadeHistoryScreen extends StatefulWidget {
  const ParadeHistoryScreen({super.key});

  @override
  State<ParadeHistoryScreen> createState() => _ParadeHistoryScreenState();
}

class _ParadeHistoryScreenState extends State<ParadeHistoryScreen> {
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
                "Parade History",
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

                final now = DateTime.now();
                // Normalize 'now' to start of today effectively if needed,
                // but strictly 'past' usually means < today's date (ignoring time if parade date is just yyyy-MM-dd)
                // Assuming parade.date is yyyy-MM-dd.
                // Let's rely on string comparison or parsing. Parsing is safer.

                final allParades = snapshot.data!.docs
                    .map((doc) {
                      return ParadeModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      );
                    })
                    .where((p) {
                      // 1. Managable years filter
                      if (manageableYears != null &&
                          !manageableYears.contains(p.targetYear)) {
                        return false;
                      }

                      // 2. History filter: Date < Today
                      try {
                        final pDate = DateTime.parse(p.date);
                        // Check if date is before today (ignoring time component of today for stricter "past")
                        // Actually, if parade was yesterday, it's history.
                        // If parade is today, it's arguably "Active/Manage".
                        final today = DateTime(now.year, now.month, now.day);
                        final pDateOnly = DateTime(
                          pDate.year,
                          pDate.month,
                          pDate.day,
                        );

                        return pDateOnly.isBefore(today);
                      } catch (e) {
                        return false;
                      }
                    })
                    .toList();

                // Sort descending for history (newest history first)
                allParades.sort((a, b) => b.date.compareTo(a.date));

                if (singleYearView) {
                  return _buildParadeList(allParades, manageableYears.first);
                }

                return TabBarView(
                  children: [
                    _buildParadeList(allParades, "All"),
                    _buildParadeList(allParades, "1st Year"),
                    _buildParadeList(allParades, "2nd Year"),
                    _buildParadeList(allParades, "3rd Year"),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildParadeList(List<ParadeModel> allParades, String year) {
    final filteredParades = year == "All"
        ? allParades
        : allParades.where((p) => p.targetYear == year).toList();

    if (filteredParades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "No Past Parades for $year",
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
        return _buildParadeCard(context, filteredParades[index]);
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
            "No Parade History",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildParadeCard(BuildContext context, ParadeModel parade) {
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
                        color: Colors.grey, // Greyed out for history
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        parade.targetYear,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
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
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
