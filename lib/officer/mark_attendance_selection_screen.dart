import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ncc_cadet/models/parade_model.dart';
import 'package:ncc_cadet/models/camp_model.dart';
import 'package:ncc_cadet/models/exam_model.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/officer/mark_attendance_screen.dart';
import 'package:ncc_cadet/officer/mark_exam_results_screen.dart';
import 'package:ncc_cadet/officer/mark_camp_attendance_screen.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/services/parade_service.dart';
import 'package:ncc_cadet/services/camp_service.dart';
import 'package:ncc_cadet/services/exam_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:ncc_cadet/utils/access_control.dart';
import 'package:ncc_cadet/officer/mark_attendance_history_screen.dart';

class MarkAttendanceSelectionScreen extends StatefulWidget {
  const MarkAttendanceSelectionScreen({super.key});

  @override
  State<MarkAttendanceSelectionScreen> createState() =>
      _MarkAttendanceSelectionScreenState();
}

class _MarkAttendanceSelectionScreenState
    extends State<MarkAttendanceSelectionScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  late Future<UserModel?> _profileFuture;

  // Cache streams to prevent reloading on setState
  Stream<QuerySnapshot>? _paradeStream;
  Stream<QuerySnapshot>? _campStream;
  Stream<QuerySnapshot>? _examStream;
  String? _loadedOrgId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _profileFuture = AuthService().getUserProfile();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // --- Robust Date Parser ---
  DateTime? _robustParse(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    final cleanStr = dateStr.trim();
    try {
      return DateTime.parse(cleanStr);
    } catch (_) {}
    final formats = [
      'MMM d, yyyy',
      'd MMM yyyy',
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'yyyy-MM-dd',
    ];
    for (final fmt in formats) {
      try {
        return DateFormat(fmt).parse(cleanStr);
      } catch (_) {}
    }
    return null;
  }

  // Initialize streams once we have the Org ID
  void _initStreams(String orgId) {
    if (_loadedOrgId == orgId) return;
    _loadedOrgId = orgId;
    _paradeStream = ParadeService().getParadesStream(orgId);
    _campStream = CampService().getCamps(orgId);
    _examStream = ExamService().getOfficerExams(orgId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _profileFuture,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.accentBlue),
            ),
          );
        }
        final officer = userSnapshot.data;
        if (officer != null) {
          _initStreams(officer.organizationId);
        }

        return Scaffold(
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
              "Select Event",
              style: TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            backgroundColor: AppTheme.navyBlue,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppTheme.accentBlue,
              unselectedLabelColor: Colors.white70,
              indicatorColor: AppTheme.accentBlue,
              tabs: const [
                Tab(text: "Parades"),
                Tab(text: "Camps"),
                Tab(text: "Exams"),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                tooltip: "Past Events",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MarkAttendanceHistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: officer == null
              ? const Center(child: Text("Error fetching profile"))
              : Column(
                  children: [
                    // --- Filter & Search Section ---
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: "Search...",
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: AppTheme.lightGrey,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildParadeList(officer),
                          _buildCampList(officer),
                          _buildExamList(officer),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // --- Parades ---
  Widget _buildParadeList(UserModel officer) {
    if (_paradeStream == null)
      return const Center(child: CircularProgressIndicator());

    final manageableYears = getManageableYears(officer);
    List<String> yearsToShow = ['1st Year', '2nd Year', '3rd Year'];
    if (manageableYears != null && manageableYears.isNotEmpty) {
      yearsToShow = manageableYears;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final searchText = _searchController.text.toLowerCase();

    // Helpers
    List<ParadeModel> getFilteredItems(List<ParadeModel> allItems) {
      // Filter Future/Today AND Search Text
      final filtered = allItems.where((p) {
        // 1. Search filter
        if (!p.name.toLowerCase().contains(searchText)) return false;

        // 2. Date filter (Future/Today only)
        final pDate = _robustParse(p.date);
        if (pDate == null) return true; // Keep if parse fails (safety)
        final nDate = DateTime(pDate.year, pDate.month, pDate.day);
        return !nDate.isBefore(today);
      }).toList();

      // Sort: Closest date first
      filtered.sort((a, b) {
        final da = _robustParse(a.date);
        final db = _robustParse(b.date);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
      return filtered;
    }

    List<ParadeModel> getForYear(List<ParadeModel> items, String year) {
      return items
          .where((p) => p.targetYear == year || p.targetYear == 'All')
          .toList();
    }

    // Single year view optimization
    if (yearsToShow.length == 1) {
      return StreamBuilder<QuerySnapshot>(
        stream: _paradeStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final allItems = snapshot.data!.docs
              .map(
                (d) =>
                    ParadeModel.fromMap(d.data() as Map<String, dynamic>, d.id),
              )
              .toList();
          final filtered = getFilteredItems(allItems);
          return _buildParadeListView(
            getForYear(filtered, yearsToShow.first),
            "No ${yearsToShow.first} parades found",
          );
        },
      );
    }

    return DefaultTabController(
      length: yearsToShow.length,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: AppTheme.navyBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.navyBlue,
              indicatorSize: TabBarIndicatorSize.label,
              isScrollable: yearsToShow.length > 3,
              tabs: yearsToShow.map((y) => Tab(text: y)).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _paradeStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final allItems = snapshot.data!.docs
                    .map(
                      (d) => ParadeModel.fromMap(
                        d.data() as Map<String, dynamic>,
                        d.id,
                      ),
                    )
                    .toList();
                final filtered = getFilteredItems(allItems);

                return TabBarView(
                  children: yearsToShow
                      .map(
                        (y) => _buildParadeListView(
                          getForYear(filtered, y),
                          "No $y parades found",
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParadeListView(List<ParadeModel> parades, String emptyMsg) {
    if (parades.isEmpty) return _buildEmptyState(emptyMsg);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: parades.length,
      itemBuilder: (ctx, i) => _buildParadeCard(ctx, parades[i]),
    );
  }

  Widget _buildParadeCard(BuildContext context, ParadeModel parade) {
    final parsedDate = _robustParse(parade.date);
    final dateStr = parsedDate != null
        ? DateFormat('MMM d, yyyy').format(parsedDate)
        : parade.date;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MarkAttendanceScreen(parade: parade),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "$dateStr at ${parade.time}",
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Mark Attendance",
                    style: TextStyle(
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppTheme.accentBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Camps ---
  Widget _buildCampList(UserModel officer) {
    if (_campStream == null)
      return const Center(child: CircularProgressIndicator());

    final manageableYears = getManageableYears(officer);
    List<String> yearsToShow = ['1st Year', '2nd Year', '3rd Year'];
    if (manageableYears != null && manageableYears.isNotEmpty) {
      yearsToShow = manageableYears;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final searchText = _searchController.text.toLowerCase();

    List<CampModel> getFilteredItems(List<CampModel> allItems) {
      final filtered = allItems.where((c) {
        // 1. Search
        if (!c.name.toLowerCase().contains(searchText)) return false;

        // 2. Active camps (EndDate >= Today)
        final eDate = _robustParse(c.endDate);
        if (eDate == null) return true;
        final nDate = DateTime(eDate.year, eDate.month, eDate.day);
        return !nDate.isBefore(today);
      }).toList();

      filtered.sort((a, b) {
        final da = _robustParse(a.startDate);
        final db = _robustParse(b.startDate);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
      return filtered;
    }

    List<CampModel> getForYear(List<CampModel> items, String year) {
      return items
          .where((c) => c.targetYear == year || c.targetYear == 'All')
          .toList();
    }

    if (yearsToShow.length == 1) {
      return StreamBuilder<QuerySnapshot>(
        stream: _campStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final allItems = snapshot.data!.docs
              .map(
                (d) =>
                    CampModel.fromMap(d.data() as Map<String, dynamic>, d.id),
              )
              .toList();
          final filtered = getFilteredItems(allItems);
          return _buildCampListView(
            getForYear(filtered, yearsToShow.first),
            "No ${yearsToShow.first} camps found",
          );
        },
      );
    }

    return DefaultTabController(
      length: yearsToShow.length,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: AppTheme.navyBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.navyBlue,
              indicatorSize: TabBarIndicatorSize.label,
              isScrollable: yearsToShow.length > 3,
              tabs: yearsToShow.map((y) => Tab(text: y)).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _campStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final allItems = snapshot.data!.docs
                    .map(
                      (d) => CampModel.fromMap(
                        d.data() as Map<String, dynamic>,
                        d.id,
                      ),
                    )
                    .toList();
                final filtered = getFilteredItems(allItems);
                return TabBarView(
                  children: yearsToShow
                      .map(
                        (y) => _buildCampListView(
                          getForYear(filtered, y),
                          "No $y camps found",
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampListView(List<CampModel> camps, String emptyMsg) {
    if (camps.isEmpty) return _buildEmptyState(emptyMsg);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: camps.length,
      itemBuilder: (ctx, i) => _buildCampCard(ctx, camps[i]),
    );
  }

  Widget _buildCampCard(BuildContext context, CampModel camp) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MarkCampAttendanceScreen(camp: camp),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                camp.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                camp.location,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                "${camp.startDate} - ${camp.endDate}",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Exams ---
  Widget _buildExamList(UserModel officer) {
    if (_examStream == null)
      return const Center(child: CircularProgressIndicator());

    final manageableYears = getManageableYears(officer);
    List<String> yearsToShow = ['1st Year', '2nd Year', '3rd Year'];
    if (manageableYears != null && manageableYears.isNotEmpty) {
      yearsToShow = manageableYears;
    } else if (manageableYears == null) {
      yearsToShow = ['2nd Year', '3rd Year'];
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final searchText = _searchController.text.toLowerCase();

    List<ExamModel> getFilteredItems(List<ExamModel> allItems) {
      final filtered = allItems.where((e) {
        // 1. Search
        if (!e.title.toLowerCase().contains(searchText)) return false;

        // 2. Future/Today
        final eDate = _robustParse(e.endDate);
        if (eDate == null) return true;
        final nDate = DateTime(eDate.year, eDate.month, eDate.day);
        return !nDate.isBefore(today);
      }).toList();

      filtered.sort((a, b) {
        final da = _robustParse(a.startDate);
        final db = _robustParse(b.startDate);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
      return filtered;
    }

    List<ExamModel> getForYear(List<ExamModel> items, String year) {
      return items
          .where((e) => e.targetYear == year || e.targetYear == 'All')
          .toList();
    }

    if (yearsToShow.length == 1) {
      return StreamBuilder<QuerySnapshot>(
        stream: _examStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final allItems = snapshot.data!.docs
              .map(
                (d) =>
                    ExamModel.fromMap(d.data() as Map<String, dynamic>, d.id),
              )
              .toList();
          final filtered = getFilteredItems(allItems);
          return _buildExamListView(
            getForYear(filtered, yearsToShow.first),
            "No ${yearsToShow.first} exams found",
          );
        },
      );
    }

    return DefaultTabController(
      length: yearsToShow.length,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: AppTheme.navyBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.navyBlue,
              indicatorSize: TabBarIndicatorSize.label,
              isScrollable: yearsToShow.length > 3,
              tabs: yearsToShow.map((y) => Tab(text: y)).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _examStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final allItems = snapshot.data!.docs
                    .map(
                      (d) => ExamModel.fromMap(
                        d.data() as Map<String, dynamic>,
                        d.id,
                      ),
                    )
                    .toList();
                final filtered = getFilteredItems(allItems);
                return TabBarView(
                  children: yearsToShow
                      .map(
                        (y) => _buildExamListView(
                          getForYear(filtered, y),
                          "No $y exams found",
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamListView(List<ExamModel> exams, String emptyMsg) {
    if (exams.isEmpty) return _buildEmptyState(emptyMsg);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exams.length,
      itemBuilder: (ctx, i) => _buildExamCard(ctx, exams[i]),
    );
  }

  Widget _buildExamCard(BuildContext context, ExamModel exam) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MarkExamResultsScreen(exam: exam),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exam.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              Text(
                exam.type,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                "${exam.startDate} - ${exam.endDate}",
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Mark Results",
                    style: TextStyle(
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppTheme.accentBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
