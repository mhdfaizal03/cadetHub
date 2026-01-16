import 'package:flutter/material.dart';
import 'package:ncc_cadet/utils/theme.dart';

class OfficerAttendanceReport extends StatefulWidget {
  const OfficerAttendanceReport({super.key});

  @override
  State<OfficerAttendanceReport> createState() =>
      _OfficerAttendanceReportState();
}

class _OfficerAttendanceReportState extends State<OfficerAttendanceReport> {
  String _selectedYear = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Unit Attendance Report",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Year Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: ["All", "1st Year", "2nd Year", "3rd Year"].map((
                  year,
                ) {
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
                      selectedColor: AppTheme.accentBlue.withOpacity(0.1),
                      checkmarkColor: AppTheme.accentBlue,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppTheme.accentBlue
                            : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            _sectionTitle("Unit Overview"),
            const SizedBox(height: 12),
            _buildUnitSummaryCard(),

            const SizedBox(height: 28),

            _sectionTitle("Status Breakdown"),
            const SizedBox(height: 12),
            _buildBreakdownRow(),

            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle("Recent Parades"),
                TextButton(onPressed: () {}, child: const Text("View All")),
              ],
            ),
            const SizedBox(height: 8),
            _buildParadeList(),
          ],
        ),
      ),
    );
  }

  // ---------------- UI COMPONENTS ----------------

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildUnitSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardStyle(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Average Attendance",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "94.2%",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlueBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: AppTheme.accentBlue,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.942,
              minHeight: 8,
              backgroundColor: AppTheme.lightBlueBg,
              valueColor: AlwaysStoppedAnimation(AppTheme.accentBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow() {
    return Row(
      children: [
        _buildSmallStatCard("Present", "228", Colors.green),
        const SizedBox(width: 12),
        _buildSmallStatCard("Absent", "12", Colors.red),
        const SizedBox(width: 12),
        _buildSmallStatCard("On Leave", "05", Colors.orange),
      ],
    );
  }

  Widget _buildSmallStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: _cardStyle(),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParadeList() {
    final sessions = [
      {"name": "Weekly Drill", "date": "2024-10-20", "perc": "96%"},
      {"name": "Physical Training", "date": "2024-10-18", "perc": "92%"},
      {"name": "Theory Class", "date": "2024-10-15", "perc": "95%"},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = sessions[index];
        return Container(
          decoration: _cardStyle(),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            title: Text(
              item['name']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              item['date']!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item['perc']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            onTap: () {},
          ),
        );
      },
    );
  }

  BoxDecoration _cardStyle() {
    return BoxDecoration(
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
    );
  }
}
