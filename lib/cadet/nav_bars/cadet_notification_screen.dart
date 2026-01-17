import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ncc_cadet/models/notification_model.dart';
import 'package:ncc_cadet/providers/user_provider.dart';
import 'package:ncc_cadet/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CadetNotificationsScreen extends StatelessWidget {
  const CadetNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User session error")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: NotificationService().getNotifications(
          user.organizationId,
          user.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // 1. Map to Model
          final allNotifications = snapshot.data!.docs.map((doc) {
            return NotificationModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

          // 2. Filter by Year
          final filteredNotifications = allNotifications.where((n) {
            // Include if targetYear is 'All' OR matches user's year
            // Also include if it's a personal notification (often type='cadet') where targetYear might not be irrelevant or set to All.
            // Assuming personal notifications might have targetYear='All' or null safe.
            // Safest: check if targetYear matches.
            return n.targetYear == 'All' || n.targetYear == user.year;
          }).toList();

          // 3. Sort
          filteredNotifications.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          );

          if (filteredNotifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredNotifications.length,
            itemBuilder: (context, index) {
              final notification = filteredNotifications[index];
              return _NotificationTile(
                title: notification.title,
                date: DateFormat('MMM d, yyyy').format(notification.createdAt),
                desc: notification.message,
                isImportant: notification.type == 'organization',
                targetYear: notification.targetYear,
              );
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
          Icon(Icons.notifications_none_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("No new notifications", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title, date, desc;
  final bool isImportant;
  final String targetYear;

  const _NotificationTile({
    required this.title,
    required this.date,
    required this.desc,
    this.isImportant = false,
    required this.targetYear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isImportant ? const Color(0xFFE8F0FF) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isImportant ? Colors.blue : Colors.grey.shade200,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
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
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Row(
                children: [
                  if (targetYear != 'All')
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        targetYear,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isImportant)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "Official",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
