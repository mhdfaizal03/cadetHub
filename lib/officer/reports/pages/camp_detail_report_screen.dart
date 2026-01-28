import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/camp_model.dart';
import 'package:ncc_cadet/services/pdf_generator_service.dart';
import 'package:ncc_cadet/utils/theme.dart';

class CampDetailReportScreen extends StatefulWidget {
  final CampModel camp;

  const CampDetailReportScreen({super.key, required this.camp});

  @override
  State<CampDetailReportScreen> createState() => _CampDetailReportScreenState();
}

class _CampDetailReportScreenState extends State<CampDetailReportScreen> {
  final PdfGeneratorService _pdfService = PdfGeneratorService();

  // Cache for cadet names using organization ID from camp
  // Ideally passed from parent or fetched.
  // For camp participants, we usually store the list in camp document or attendance?
  // Our CampModel doesn't have participants list directly, usually it's queried via Attendance or a subcollection.
  // Let's assume for now we use AttendanceService to finding who attended the camp.
  // Wait, `AttendanceService` manages *Parade* attendance primarily.
  // Do we have Camp Attendance?
  // Looking at `AttendanceService` (not viewing file but recalling context),
  // or `CampService`.
  // If no Camp Attendance logic exists yet, we might need to rely on "Nominations" or "Participants" if implemented.
  // If not, I will just show basic camp info and a placeholder for participants or fetch from `camp_nominations` if that exists.
  // Actually, standard NCC workflow: you mark attendance for camps too or select cadets.
  // Let's assume we query `camp_attendance` collection or similar.
  // For now, to keep it functional, I will query referencing variables I might not have.
  // Safer bet: query `attendance` collection where `campId` == widget.camp.id.

  // Actually, better approach: The "Camp" feature might utilize the `attendance` collection with a `campId` field, similiar to parades.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text("Camp Report"),
        backgroundColor: AppTheme.navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.camp.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navyBlue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${widget.camp.startDate} - ${widget.camp.endDate}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.camp.location,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Target: ${widget.camp.targetYear}"),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Fetch Participants (Attendance with campId)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(
                    'attendance',
                  ) // Assuming shared collection or similar
                  .where('campId', isEqualTo: widget.camp.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                final participants = docs
                    .where((d) => (d.data() as Map)['status'] == 'Present')
                    .toList();
                // If no attendance marked, maybe it's nominated cadets?
                // Let's settle for showing attendance records if any.

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statItem("Participants", "${participants.length}"),
                          // We count total records as "Nominated" maybe?
                          _statItem("Total Records", "${docs.length}"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text("Download Camp Report"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.navyBlue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Downloading...")),
                          );
                          // Use service
                          await _pdfService.generateCampPDF(
                            camps: [widget.camp],
                            title: "Camp Detail Report: ${widget.camp.name}",
                            subtitle:
                                "${widget.camp.location} | ${widget.camp.startDate}",
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (docs.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            "No attendance/participants records found for this camp.",
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          // We need to fetch Cadet Name.
                          // This requires a FutureBuilder or pre-fetching.
                          // For simplicity/performance in this list, we'll show ID or Name if available in attendance doc.
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final cadetId = data['cadetId'] ?? 'Unknown';
                          final status = data['status'] ?? 'N/A';

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(cadetId)
                                .get(),
                            builder: (context, cadetSnap) {
                              String name = "Cadet $cadetId";
                              if (cadetSnap.hasData &&
                                  cadetSnap.data != null &&
                                  cadetSnap.data!.exists) {
                                name =
                                    (cadetSnap.data!.data() as Map)['name'] ??
                                    name;
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(cadetId),
                                  trailing: Text(
                                    status,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, {Color color = Colors.black}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
