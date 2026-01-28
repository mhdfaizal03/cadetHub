import 'package:flutter/material.dart';
import 'package:ncc_cadet/officer/reports/views/attendance_report_view.dart';
import 'package:ncc_cadet/officer/reports/views/exam_report_view.dart';
import 'package:ncc_cadet/officer/reports/views/camp_report_view.dart';
import 'package:ncc_cadet/officer/reports/views/parade_report_view.dart';
import 'package:ncc_cadet/utils/theme.dart';

class ReportsDashboard extends StatelessWidget {
  const ReportsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppTheme.lightGrey,
        appBar: AppBar(
          title: const Text("Reports & Analytics"),
          backgroundColor: AppTheme.navyBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_left),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppTheme.accentBlue,
            labelColor: AppTheme.accentBlue,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Attendance"),
              Tab(text: "Parades"),
              Tab(text: "Exams"),
              Tab(text: "Camps"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AttendanceReportView(),
            ParadeReportView(),
            ExamReportView(),
            CampReportView(),
          ],
        ),
      ),
    );
  }
}
