import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/camp_model.dart';
import 'package:ncc_cadet/services/camp_service.dart';
import 'package:ncc_cadet/utils/theme.dart';

class CampParticipantsScreen extends StatefulWidget {
  final CampModel camp;
  const CampParticipantsScreen({super.key, required this.camp});

  @override
  State<CampParticipantsScreen> createState() => _CampParticipantsScreenState();
}

class _CampParticipantsScreenState extends State<CampParticipantsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppTheme.navyBlue,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.camp.name,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          bottom: const TabBar(
            indicatorColor: AppTheme.accentBlue,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Going"),
              Tab(text: "Not Going"),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: CampService().getCampResponses(widget.camp.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No responses yet",
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            final docs = snapshot.data!.docs;
            final going = docs.where((d) => d['response'] == 'Going').toList();
            final notGoing = docs
                .where((d) => d['response'] == 'Not Going')
                .toList();

            return TabBarView(
              children: [_buildList(going), _buildList(notGoing)],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return const Center(
        child: Text(
          "No cadets in this list",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final String name = data['cadetName'] ?? 'Unknown';

        return Card(
          elevation: 0,
          color: Colors.grey.shade50,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.navyBlue.withOpacity(0.1),
              child: Text(
                name[0],
                style: const TextStyle(color: AppTheme.navyBlue),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // We could fetch more details like Year/Rank if we query User collection by ID.
            // keeping it simple for now as requested.
          ),
        );
      },
    );
  }
}
