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
  DateTime? _selectedDate;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: AuthService().getUserProfile(),
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
                          Row(children: [Expanded(child: _buildDateFilter())]),
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

  Widget _buildDateFilter() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              _selectedDate == null
                  ? "Filter by Date"
                  : DateFormat('dd MMM yyyy').format(_selectedDate!),
              style: TextStyle(
                color: _selectedDate == null
                    ? Colors.grey.shade600
                    : Colors.black,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            if (_selectedDate != null)
              GestureDetector(
                onTap: () => setState(() => _selectedDate = null),
                child: const Icon(Icons.close, size: 16, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  // --- Parades ---
  Widget _buildParadeList(UserModel officer) {
    // 1. Determine Years to Show
    final manageableYears = getManageableYears(officer);
    List<String> yearsToShow = ['1st Year', '2nd Year', '3rd Year'];
    if (manageableYears != null && manageableYears.isNotEmpty) {
      yearsToShow = manageableYears;
    }

    // 2. Hide Tabs if only one year
    if (yearsToShow.length == 1) {
      return StreamBuilder<QuerySnapshot>(
        stream: ParadeService().getParadesStream(officer.organizationId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allItems = snapshot.data!.docs
              .map(
                (d) =>
                    ParadeModel.fromMap(d.data() as Map<String, dynamic>, d.id),
              )
              .toList();

          // Helper
          List<ParadeModel> getForYear(String year) {
            final yearItems = allItems
                .where((p) => p.targetYear == year || p.targetYear == 'All')
                .toList();
            return _filterItems(yearItems, (i) => i.name, (i) => i.date);
          }

          return _buildParadeListView(
            getForYear(yearsToShow.first),
            "No ${yearsToShow.first} parades",
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
              isScrollable:
                  yearsToShow.length > 3, // Enable scrolling if many items
              tabs: yearsToShow.map((y) => Tab(text: y)).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ParadeService().getParadesStream(officer.organizationId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allItems = snapshot.data!.docs
                    .map(
                      (d) => ParadeModel.fromMap(
                        d.data() as Map<String, dynamic>,
                        d.id,
                      ),
                    )
                    .toList();

                // Helper to filter by year and search
                List<ParadeModel> getForYear(String year) {
                  final yearItems = allItems
                      .where(
                        (p) => p.targetYear == year || p.targetYear == 'All',
                      )
                      .toList();
                  return _filterItems(yearItems, (i) => i.name, (i) => i.date);
                }

                return TabBarView(
                  children: yearsToShow
                      .map(
                        (y) => _buildParadeListView(
                          getForYear(y),
                          "No $y parades",
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
                    "${DateFormat('MMM d, yyyy').format(DateTime.parse(parade.date))} at ${parade.time}",
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
    // 1. Determine Years to Show
    final manageableYears = getManageableYears(officer);
    List<String> yearsToShow = ['1st Year', '2nd Year', '3rd Year'];
    if (manageableYears != null && manageableYears.isNotEmpty) {
      yearsToShow = manageableYears;
    }

    // 2. Hide Tabs if only one year
    if (yearsToShow.length == 1) {
      return StreamBuilder<QuerySnapshot>(
        stream: CampService().getCamps(officer.organizationId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allItems = snapshot.data!.docs
              .map(
                (d) =>
                    CampModel.fromMap(d.data() as Map<String, dynamic>, d.id),
              )
              .toList();

          List<CampModel> getForYear(String year) {
            final yearItems = allItems
                .where((c) => c.targetYear == year || c.targetYear == 'All')
                .toList();
            return _filterItems(yearItems, (i) => i.name, (i) => i.startDate);
          }

          return _buildCampListView(
            getForYear(yearsToShow.first),
            "No ${yearsToShow.first} camps",
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
              stream: CampService().getCamps(officer.organizationId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allItems = snapshot.data!.docs
                    .map(
                      (d) => CampModel.fromMap(
                        d.data() as Map<String, dynamic>,
                        d.id,
                      ),
                    )
                    .toList();

                List<CampModel> getForYear(String year) {
                  final yearItems = allItems
                      .where(
                        (c) => c.targetYear == year || c.targetYear == 'All',
                      )
                      .toList();
                  return _filterItems(
                    yearItems,
                    (i) => i.name,
                    (i) => i.startDate,
                  );
                }

                return TabBarView(
                  children: yearsToShow
                      .map(
                        (y) => _buildCampListView(getForYear(y), "No $y camps"),
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
    // 1. Determine Years to Show
    final manageableYears = getManageableYears(officer);
    List<String> yearsToShow = ['1st Year', '2nd Year', '3rd Year'];
    // For exams, usually only for 2nd and 3rd year (B and C cert), but let's keep it generic.
    // If strict compliance:
    // "There is no exam for 1st Year generally" - but codebase had '2nd Year', '3rd Year' hardcoded.
    // If we just use manageableYears, it might include '1st Year' if UO is 1st Year (unlikely).
    // Let's stick to intersection of manageableYears and ['2nd Year', '3rd Year'] if we want to mimic previous behavior,
    // OR just show whatever manageableYears allows.
    // Given the user request is "Under officer can permit to mark his year students only",
    // if a 2nd Year UO needs to mark 2nd Year exams, they should see 2nd Year tab.
    // If 3rd Year UO, they see 3rd Year tab.
    // Currently logic:
    // if manageableYears != null, use that.

    if (manageableYears != null && manageableYears.isNotEmpty) {
      yearsToShow = manageableYears;
    } else {
      // Default behavior was 2nd and 3rd year only.
      // We should preserve that for full access officers?
      // Previous code had 2 tabs: 2nd and 3rd.
      if (manageableYears == null) {
        yearsToShow = ['2nd Year', '3rd Year'];
      }
    }

    // 2. Hide Tabs if only one year
    if (yearsToShow.length == 1) {
      return StreamBuilder<QuerySnapshot>(
        stream: ExamService().getOfficerExams(officer.organizationId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allItems = snapshot.data!.docs
              .map(
                (d) =>
                    ExamModel.fromMap(d.data() as Map<String, dynamic>, d.id),
              )
              .toList();

          List<ExamModel> getForYear(String year) {
            final yearItems = allItems
                .where((e) => e.targetYear == year || e.targetYear == 'All')
                .toList();
            return _filterItems(yearItems, (i) => i.title, (i) => i.startDate);
          }

          return _buildExamListView(
            getForYear(yearsToShow.first),
            "No ${yearsToShow.first} exams",
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
              stream: ExamService().getOfficerExams(officer.organizationId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allItems = snapshot.data!.docs
                    .map(
                      (d) => ExamModel.fromMap(
                        d.data() as Map<String, dynamic>,
                        d.id,
                      ),
                    )
                    .toList();

                List<ExamModel> getForYear(String year) {
                  // Exams targetYear might be '2nd Year', '3rd Year', or 'All'
                  final yearItems = allItems
                      .where(
                        (e) => e.targetYear == year || e.targetYear == 'All',
                      )
                      .toList();
                  return _filterItems(
                    yearItems,
                    (i) => i.title,
                    (i) => i.startDate,
                  );
                }

                return TabBarView(
                  children: yearsToShow
                      .map(
                        (y) => _buildExamListView(getForYear(y), "No $y exams"),
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
                ),
              ),
              Text(
                exam.type,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                "${exam.startDate} - ${exam.endDate}",
                style: const TextStyle(fontWeight: FontWeight.w500),
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

  // --- Helpers ---

  // Generic Filter
  List<T> _filterItems<T>(
    List<T> items,
    String Function(T) getName,
    String Function(T) getDateStr,
  ) {
    return items.where((item) {
      final matchesSearch = getName(
        item,
      ).toLowerCase().contains(_searchController.text.toLowerCase());
      bool matchesDate = true;
      if (_selectedDate != null) {
        try {
          final dateStr = getDateStr(item);
          // Simple string substring match as backup to robust parsing
          final filterStr = DateFormat('dd-MM-yyyy').format(_selectedDate!);
          // Try strict or partial
          matchesDate =
              dateStr.contains(filterStr) ||
              dateStr.contains(
                DateFormat('yyyy-MM-dd').format(_selectedDate!),
              ) ||
              dateStr.contains(DateFormat('dd/MM/yyyy').format(_selectedDate!));
        } catch (e) {
          matchesDate = false;
        }
      }
      return matchesSearch && matchesDate;
    }).toList();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppTheme.accentBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
