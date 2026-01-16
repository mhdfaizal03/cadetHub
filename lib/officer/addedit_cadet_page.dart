import 'package:flutter/material.dart';
import 'package:ncc_cadet/services/auth_service.dart';

class AddEditCadetPage extends StatefulWidget {
  final Map<String, dynamic>?
  cadetData; // Null if adding, contains data if editing

  const AddEditCadetPage({super.key, this.cadetData});

  @override
  State<AddEditCadetPage> createState() => _AddEditCadetPageState();
}

class _AddEditCadetPageState extends State<AddEditCadetPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // Controllers for text fields
  late TextEditingController _nameController;
  late TextEditingController _idController;
  late TextEditingController _phoneController;

  // State for dropdowns
  String _selectedUnit = 'Alpha';
  String _selectedRank = 'Cadet';
  String _selectedStatus = 'Active';

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data if editing
    _nameController = TextEditingController(
      text: widget.cadetData?['name'] ?? '',
    );
    _idController = TextEditingController(text: widget.cadetData?['id'] ?? '');
    _phoneController = TextEditingController(
      text: widget.cadetData?['phone'] ?? '',
    );
    if (widget.cadetData != null) {
      _selectedUnit = widget.cadetData?['unit'] ?? 'Alpha';
      _selectedRank = widget.cadetData?['rank'] ?? 'Cadet';
      _selectedStatus = widget.cadetData?['status'] ?? 'Active';
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.cadetData != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? "Edit Cadet" : "Add New Cadet"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo Placeholder
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade100,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              _buildSectionLabel("Personal Information"),
              const SizedBox(height: 16),
              _buildTextField(
                label: "Full Name",
                controller: _nameController,
                hint: "Enter cadet's full name",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: "Cadet ID",
                controller: _idController,
                hint: "e.g. NCC/2023/1001",
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 30),

              _buildSectionLabel("Service Details"),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: "Unit",
                      value: _selectedUnit,
                      items: ['Alpha', 'Bravo', 'Charlie', 'Delta'],
                      onChanged: (val) => setState(() => _selectedUnit = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: "Rank",
                      value: _selectedRank,
                      items: ['Cadet', 'Corporal', 'Sergeant', 'Under Officer'],
                      onChanged: (val) => setState(() => _selectedRank = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                label: "Enrollment Status",
                value: _selectedStatus,
                items: ['Active', 'Inactive', 'Pending'],
                onChanged: (val) => setState(() => _selectedStatus = val!),
              ),
              const SizedBox(height: 40),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveCadet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5CFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isEditing ? "Update Cadet Info" : "Register Cadet",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (!isEditing)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: const Text(
                    "Note: New cadets should preferably register themselves via the app using the Organization Code.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCadet() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if editing
    if (widget.cadetData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please ask the cadet to register via the app."),
        ),
      );
      return;
    }

    final uid = widget.cadetData!['uid'];

    // Convert status string to integer
    int statusInt = 0;
    if (_selectedStatus == 'Active') statusInt = 1;
    if (_selectedStatus == 'Inactive') statusInt = -1;
    if (_selectedStatus == 'Pending') statusInt = 0;

    try {
      await _authService.updateUserData(uid, {
        'name': _nameController.text.trim(),
        'cadetId': _idController.text
            .trim(), // Assuming 'cadetId' is the field name
        // 'phone': _phoneController.text.trim(), // Remove if phone not in use or add controller
        'unit': _selectedUnit,
        'rank': _selectedRank,
        'status': statusInt,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cadet updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- UI Builders ---

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: (value) => value!.isEmpty ? "Field required" : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1D5CFF)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1D5CFF)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((String item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
