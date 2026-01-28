import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/camp_model.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/services/camp_service.dart';
import 'package:ncc_cadet/services/pdf_generator_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:ncc_cadet/utils/access_control.dart';
import 'package:ncc_cadet/officer/reports/pages/camp_detail_report_screen.dart';

class CampReportView extends StatefulWidget {
  const CampReportView({super.key});

  @override
  State<CampReportView> createState() => _CampReportViewState();
}

class _CampReportViewState extends State<CampReportView> {
  final AuthService _authService = AuthService();
  final CampService _campService = CampService();
  final PdfGeneratorService _pdfService = PdfGeneratorService();

  String _selectedYear = 'All';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _authService.getUserProfile(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final officer = userSnapshot.data!;

        final manageableYears = getManageableYears(officer);
        List<String> yearOptions = ['All', '1st Year', '2nd Year', '3rd Year'];
        if (manageableYears != null) {
          yearOptions = manageableYears;
          if (!yearOptions.contains(_selectedYear)) {
            _selectedYear = yearOptions.first;
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _campService.getCamps(officer.organizationId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allCamps = snapshot.data!.docs.map((doc) {
              return CampModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
            }).toList();

            final filteredCamps = allCamps.where((camp) {
              if (_selectedYear == 'All') return true;
              return camp.targetYear == _selectedYear;
            }).toList();

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: yearOptions.contains(_selectedYear)
                          ? _selectedYear
                          : yearOptions.first,
                      decoration: const InputDecoration(
                        labelText: "Target Year",
                        border: OutlineInputBorder(),
                      ),
                      items: yearOptions
                          .map(
                            (y) => DropdownMenuItem(value: y, child: Text(y)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedYear = val!),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.file_download),
                      label: const Text("Download Camp List"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navyBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await _pdfService.generateCampPDF(
                          camps: filteredCamps,
                          title: "Camp Schedule Report",
                          subtitle:
                              "Target Year: $_selectedYear | Total Camps: ${filteredCamps.length}",
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredCamps.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, index) {
                        final camp = filteredCamps[index];
                        return Card(
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
                                  builder: (_) =>
                                      CampDetailReportScreen(camp: camp),
                                ),
                              );
                            },
                            child: ListTile(
                              leading: Icon(
                                Icons.campaign_rounded,
                                color: AppTheme.navyBlue,
                              ),
                              title: Text(
                                camp.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "${camp.startDate} - ${camp.endDate}\n${camp.location}",
                              ),
                              isThreeLine: true,
                              trailing: Text(camp.targetYear),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
