import 'package:flutter/material.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/utils/access_control.dart';

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
  late TextEditingController _emailController;
  late TextEditingController _phoneController; // New
  late TextEditingController _addressController; // New
  late TextEditingController _passwordController;

  // State for dropdowns
  String _selectedRank = 'Cadet';
  String _selectedStatus = 'Active';
  String _selectedYear = '1st Year';

  List<String> _availableYears = ['1st Year', '2nd Year', '3rd Year'];
  bool _loadingProfile = true;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPermissions();
    // Initialize controllers with existing data if editing
    _nameController = TextEditingController(
      text: widget.cadetData?['name'] ?? '',
    );
    _idController = TextEditingController(
      text: widget.cadetData?['cadetId'] ?? '',
    );
    // Email/Password only relevant for new users usually, or editing email?
    // Let's allow editing email but not password for now (complexity).
    _emailController = TextEditingController(
      text: widget.cadetData?['email'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.cadetData?['phone'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.cadetData?['address'] ?? '',
    );
    _passwordController = TextEditingController();

    if (widget.cadetData != null) {
      _selectedRank = widget.cadetData?['rank'] ?? 'Cadet';
      final statusVal = widget.cadetData?['status'];
      if (statusVal == 1) _selectedStatus = 'Active';
      if (statusVal == 0) _selectedStatus = 'Pending';
      if (statusVal == -1) _selectedStatus = 'Inactive';

      _selectedYear = widget.cadetData?['year'] ?? '1st Year';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchPermissions() async {
    final officer = await _authService.getUserProfile();
    if (officer != null) {
      final years = getManageableYears(officer);
      if (years != null && years.isNotEmpty) {
        if (mounted) {
          setState(() {
            _availableYears = years;
            // If strictly one year, ensure it's selected
            // If editing, only change if current selection is invalid?
            // Actually, UO shouldn't even see other years' cadets to edit.
            // But if they are adding, we must force the year.
            if (!_availableYears.contains(_selectedYear)) {
              _selectedYear = _availableYears.first;
            }
          });
        }
      }
    }
    if (mounted) setState(() => _loadingProfile = false);
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.cadetData != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.keyboard_arrow_left,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? "Edit Cadet" : "Register New Cadet"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: "Email Address",
                      controller: _emailController,
                      hint: "cadet@example.com",
                      icon: Icons.email_outlined,
                      inputType: TextInputType.emailAddress,
                      readOnly:
                          isEditing, // Changing email is complex (auth sync)
                    ),
                    const SizedBox(height: 20),
                    // Phone
                    _buildTextField(
                      label: "Phone Number",
                      controller: _phoneController,
                      hint: "+91 XXXXX XXXXX",
                      icon: Icons.phone_outlined,
                      inputType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    // Address
                    _buildTextField(
                      label: "Address",
                      controller: _addressController,
                      hint: "Enter residential address",
                      icon: Icons.home_outlined,
                      maxLines: 2,
                    ),

                    if (!isEditing) ...[
                      const SizedBox(height: 20),
                      _buildTextField(
                        label: "Password",
                        controller: _passwordController,
                        hint: "Create a password",
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                    ],

                    const SizedBox(height: 30),

                    _buildSectionLabel("Service Details"),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            label: "Year",
                            value: _selectedYear,
                            items: _availableYears,
                            onChanged: (val) =>
                                setState(() => _selectedYear = val!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            label: "Rank",
                            value: _selectedRank,
                            items: [
                              'Cadet',
                              'Lance Corporal',
                              'Corporal',
                              'Sergeant',
                              'Company Quartermaster Sergeant',
                              'Company Sergeant Major',
                              'Under Officer',
                              'Senior Under Officer',
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedRank = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDropdown(
                      label: "Account Status",
                      value: _selectedStatus,
                      items: ['Active', 'Inactive', 'Pending'],
                      onChanged: (val) =>
                          setState(() => _selectedStatus = val!),
                    ),
                    const SizedBox(height: 40),

                    // Action Buttons
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveCadet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D5CFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                isEditing
                                    ? "Update Cadet Info"
                                    : "Register Cadet",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
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
    setState(() => _isLoading = true);

    try {
      // Convert status string to integer
      int statusInt = 0;
      if (_selectedStatus == 'Active') statusInt = 1;
      if (_selectedStatus == 'Inactive') statusInt = -1;
      if (_selectedStatus == 'Pending') statusInt = 0;

      if (widget.cadetData == null) {
        // --- ADD NEW CADET ---

        // Get generic user provider to get organizationId
        // Assuming we have a UserProvider or we fetch current user logic here.
        // AuthService.currentUser is available.
        final currentUserProfile = await _authService.getUserProfile();
        if (currentUserProfile == null) {
          throw Exception("Could not verify officer session.");
        }

        final error = await _authService.registerCadetByOfficer(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          cadetId: _idController.text.trim(),
          organizationId: currentUserProfile.organizationId,
          year: _selectedYear,
          rank: _selectedRank,
          status: statusInt,
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
        );

        if (error != null) {
          throw Exception(error);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cadet created successfully"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // --- EDIT EXISTING CADET ---
        final uid = widget.cadetData!['uid'];

        await _authService.updateUserData(uid, {
          'name': _nameController.text.trim(),
          'rank': _selectedRank,
          'year': _selectedYear,
          'status': statusInt,
          'cadetId': _idController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          // 'email' change is complex, skipping for now
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    bool readOnly = false,
    bool isPassword = false,
    TextInputType inputType = TextInputType.text,
    int maxLines = 1, // Added
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
          maxLines: maxLines,
          readOnly: readOnly,
          obscureText: isPassword,
          keyboardType: inputType,
          validator: (value) {
            if (value == null || value.isEmpty) return "Field required";
            if (isPassword && value.length < 6) return "Min 6 chars";
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1D5CFF)),
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
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
