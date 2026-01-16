import 'package:flutter/material.dart';
import 'package:ncc_cadet/models/camp_model.dart';
import 'package:ncc_cadet/providers/user_provider.dart';
import 'package:ncc_cadet/services/camp_service.dart';
import 'package:ncc_cadet/utils/theme.dart';
import 'package:provider/provider.dart';

class AddEditCampScreen extends StatefulWidget {
  final CampModel? camp;
  const AddEditCampScreen({super.key, this.camp});

  @override
  State<AddEditCampScreen> createState() => _AddEditCampScreenState();
}

class _AddEditCampScreenState extends State<AddEditCampScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _descriptionController;

  String _targetYear = 'All'; // Default

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.camp?.name ?? '');
    _locationController = TextEditingController(
      text: widget.camp?.location ?? '',
    );
    _startDateController = TextEditingController(
      text: widget.camp?.startDate ?? '',
    );
    _endDateController = TextEditingController(
      text: widget.camp?.endDate ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.camp?.description ?? '',
    );
    _targetYear = widget.camp?.targetYear ?? 'All';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.navyBlue, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.navyBlue, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _saveCamp() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User session error")));
      return;
    }

    try {
      final camp = CampModel(
        id: widget.camp?.id ?? '', // Service ignores ID on create
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        startDate: _startDateController.text,
        endDate: _endDateController.text,
        description: _descriptionController.text.trim(),
        organizationId: user.organizationId,
        targetYear: _targetYear,
        createdAt: widget.camp?.createdAt ?? DateTime.now(),
      );

      if (widget.camp == null) {
        await CampService().createCamp(camp);
      } else {
        await CampService().updateCamp(camp);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Camp saved successfully"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.camp == null ? "Add Camp" : "Edit Camp",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.navyBlue,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveCamp,
            child: const Text(
              "SAVE",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.accentBlue,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Camp Details"),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: "Camp Name",
                icon: Icons.flag_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _locationController,
                label: "Location",
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),
              _buildTargetYearDropdown(), // Target Year Dropdown
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(_startDateController),
                      child: AbsorbPointer(
                        child: _buildTextField(
                          controller: _startDateController,
                          label: "Start Date",
                          icon: Icons.calendar_today,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(_endDateController),
                      child: AbsorbPointer(
                        child: _buildTextField(
                          controller: _endDateController,
                          label: "End Date",
                          icon: Icons.calendar_today,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle("Additional Info"),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: "Description",
                icon: Icons.description_outlined,
                maxLines: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.navyBlue,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (v) => v!.isEmpty ? "Required" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: icon != null ? Icon(icon, color: AppTheme.navyBlue) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.navyBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildTargetYearDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonFormField<String>(
        value: _targetYear,
        decoration: const InputDecoration(
          labelText: "Target Audience",
          border: InputBorder.none,
          prefixIcon: Icon(Icons.people_outline, color: AppTheme.navyBlue),
        ),
        items: ['All', '1st Year', '2nd Year', '3rd Year']
            .map((label) => DropdownMenuItem(value: label, child: Text(label)))
            .toList(),
        onChanged: (val) => setState(() => _targetYear = val!),
      ),
    );
  }
}
