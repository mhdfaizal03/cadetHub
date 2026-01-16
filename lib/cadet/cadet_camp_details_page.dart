import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/camp_model.dart';
import 'package:ncc_cadet/providers/user_provider.dart';
import 'package:ncc_cadet/services/camp_service.dart';
import 'package:provider/provider.dart';

class CadetCampDetailsScreen extends StatelessWidget {
  const CadetCampDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User session error")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left, color: Colors.black),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          "Upcoming Camps",
          style: TextStyle(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: CampService().getCamps(user.organizationId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final allCamps = snapshot.data!.docs.map((doc) {
            return CampModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

          // Filter by Year
          final filteredCamps = allCamps.where((camp) {
            return camp.targetYear == 'All' || camp.targetYear == user.year;
          }).toList();

          if (filteredCamps.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredCamps.length,
            itemBuilder: (context, index) {
              final camp = filteredCamps[index];
              return _CampCard(camp: camp);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.terrain_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "No upcoming camps found.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _CampCard extends StatelessWidget {
  final CampModel camp;
  const _CampCard({required this.camp});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      // ... decoration ...
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                child: Text(
                  camp.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (camp.targetYear != 'All')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    camp.targetYear,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            "Date:",
            "${camp.startDate} to ${camp.endDate}",
          ),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.location_on_outlined, "Location:", camp.location),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.description_outlined,
            "Details:",
            camp.description,
          ),
          const Divider(height: 24),
          _buildParticipationSection(context),
        ],
      ),
    );
  }

  Widget _buildParticipationSection(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: CampService().getUserResponse(camp.id, user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        String? currentResponse;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          currentResponse = data['response'];
        }

        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _updateResponse(context, user, 'Going'),
                icon: currentResponse == 'Going'
                    ? const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 18,
                      )
                    : const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 18,
                      ),
                label: Text(
                  "Going",
                  style: TextStyle(
                    color: currentResponse == 'Going'
                        ? Colors.white
                        : Colors.green,
                    fontWeight: currentResponse == 'Going'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentResponse == 'Going'
                      ? Colors.green
                      : Colors.white,
                  elevation: 0,
                  side: const BorderSide(color: Colors.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _updateResponse(context, user, 'Not Going'),
                icon: currentResponse == 'Not Going'
                    ? const Icon(Icons.cancel, color: Colors.white, size: 18)
                    : const Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                        size: 18,
                      ),
                label: Text(
                  "Not Going",
                  style: TextStyle(
                    color: currentResponse == 'Not Going'
                        ? Colors.white
                        : Colors.red,
                    fontWeight: currentResponse == 'Not Going'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentResponse == 'Not Going'
                      ? Colors.red
                      : Colors.white,
                  elevation: 0,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateResponse(
    BuildContext context,
    dynamic
    user, // Using dynamic to avoid circular dependency if UserModel isn't imported here, but it is imported in file.
    String response,
  ) async {
    try {
      await CampService().updateCampResponse(
        campId: camp.id,
        cadetId: user.uid,
        cadetName: user.name,
        response: response,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Marked as $response"),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
