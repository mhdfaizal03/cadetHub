import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ncc_cadet/models/parade_model.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/officer/mark_attendance_screen.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/services/parade_service.dart';
import 'package:ncc_cadet/utils/theme.dart';

class MarkAttendanceSelectionScreen extends StatefulWidget {
  const MarkAttendanceSelectionScreen({super.key});

  @override
  State<MarkAttendanceSelectionScreen> createState() =>
      _MarkAttendanceSelectionScreenState();
}

class _MarkAttendanceSelectionScreenState
    extends State<MarkAttendanceSelectionScreen> {
  // Using AppTheme now
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.keyboard_arrow_left,
            color: Colors.black,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Select Parade",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: FutureBuilder<UserModel?>(
        future: AuthService().getUserProfile(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accentBlue),
            );
          }

          final officer = userSnapshot.data;
          if (officer == null) {
            return const Center(child: Text("Error fetching officer profile"));
          }

          return Column(
            children: [
              // --- Filter & Search Section ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search parade...",
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
                    // Date Filter Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedDate == null
                                        ? "Filter by Date"
                                        : DateFormat(
                                            'dd MMM yyyy',
                                          ).format(_selectedDate!),
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
                                      onTap: () =>
                                          setState(() => _selectedDate = null),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- Parade List ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: ParadeService().getParadesStream(
                    officer.organizationId,
                  ),
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

                    // Convert to Models
                    final allParades = snapshot.data!.docs.map((doc) {
                      return ParadeModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      );
                    }).toList();

                    // Apply Filters locally
                    final filteredParades = _filterParades(allParades);

                    if (filteredParades.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No matching parades found",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredParades.length,
                      itemBuilder: (context, index) {
                        return _buildParadeCard(
                          context,
                          filteredParades[index],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  List<ParadeModel> _filterParades(List<ParadeModel> parades) {
    return parades.where((parade) {
      bool matchesSearch = parade.name.toLowerCase().contains(
        _searchController.text.toLowerCase(),
      );

      bool matchesDate = true;
      if (_selectedDate != null) {
        try {
          // Assume parade.date is formatted string like "15 Aug 2024" or standard format
          // Need to parse it. Let's try flexible parsing or match exact format if known.
          // Based on parade card, it displays "parade.date".
          // If parade.date is "dd-MM-yyyy" or "dd/MM/yyyy"?
          // Let's assume standard parsing or specific format if you know it from ParadeModel.
          // Fallback: compare formatted strings if parsing fails/complex.

          // Better: Compare formatted _selectedDate with parade.date string
          // If parade.date is "dd-MM-yyyy", format selectedDate to "dd-MM-yyyy"

          // Checking existing parade model usage or common inputs...
          // Assuming parade.date is stored as string in UI.
          // Let's try to see if it matches the formatted selected date.

          // NOTE: If parade.date format varies, this might be brittle.
          // Ideally ParadeModel should have a DateTime object or timestamp.
          // For now, let's normalize both to string check or parse.

          // Let's try comparing substrings or using DateFormat if format known.
          // If parade.date = "2023-10-27" (ISO)
          // If parade.date = "27/10/2023"

          // Simple string match for now as a safe bet if format matches User input logic
          // Or format selectedDate to current app standard.
          // Let's go effectively with string contains for partial match if unsure,
          // OR try standard format 'dd-MM-yyyy' which seems common in this app.

          final formattedFilter = DateFormat(
            'dd-MM-yyyy',
          ).format(_selectedDate!);
          // matchesDate = parade.date == formattedFilter; // Strict
          matchesDate = parade.date.contains(formattedFilter); // looser

          // If that fails, try 'dd/MM/yyyy'
          if (!matchesDate) {
            final altFormat = DateFormat('dd/MM/yyyy').format(_selectedDate!);
            matchesDate = parade.date.contains(altFormat);
          }

          // If that fails, try 'yyyy-MM-dd'
          if (!matchesDate) {
            final isoFormat = DateFormat('yyyy-MM-dd').format(_selectedDate!);
            matchesDate = parade.date.contains(isoFormat);
          }
        } catch (e) {
          matchesDate = false;
        }
      }

      return matchesSearch && matchesDate;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No Parades Scheduled",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
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
                    "${parade.date} at ${parade.time}",
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Visual cue that this is actionable
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
                  const SizedBox(width: 4),
                  Icon(
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
}
