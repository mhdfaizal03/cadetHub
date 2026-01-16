import 'package:flutter/material.dart';
import 'package:ncc_cadet/models/parade_model.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/services/parade_service.dart';
import 'package:ncc_cadet/utils/theme.dart';

class AddEditParadeScreen extends StatefulWidget {
  final ParadeModel? parade;
  const AddEditParadeScreen({super.key, this.parade});

  @override
  State<AddEditParadeScreen> createState() => _AddEditParadeScreenState();
}

class _AddEditParadeScreenState extends State<AddEditParadeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  String _targetYear = '1st Year'; // Default to All
  // Removed static primaryColor, using AppTheme now

  @override
  void initState() {
    super.initState();
    if (widget.parade != null) {
      _nameController.text = widget.parade!.name;
      _dateController.text = widget.parade!.date;
      _timeController.text = widget.parade!.time;
      _locationController.text = widget.parade!.location;
      _descriptionController.text = widget.parade!.description;
      _targetYear = widget.parade!.targetYear;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.accentBlue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _dateController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {});
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      _timeController.text = picked.format(context);
      setState(() {});
    }
  }

  Future<void> _saveParade() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Fetch Officer Profile to get Organization ID
      final officer = await AuthService().getUserProfile();
      if (officer == null) {
        if (mounted) _showError("Error: Could not fetch officer profile.");
        return;
      }

      final paradeService = ParadeService();
      final isEditing = widget.parade != null;

      final paradeData = ParadeModel(
        id: isEditing ? widget.parade!.id : '', // ID ignored on add
        name: _nameController.text.trim(),
        date: _dateController.text.trim(),
        time: _timeController.text.trim(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        targetYear: _targetYear,
        organizationId: officer.organizationId,
        createdAt: isEditing ? widget.parade!.createdAt : DateTime.now(),
      );

      if (isEditing) {
        await paradeService.updateParade(widget.parade!.id, paradeData.toMap());
      } else {
        await paradeService.addParade(paradeData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? "Parade Updated Successfully"
                  : "Parade Scheduled Successfully",
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showError("Failed to save parade: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(
            Icons.keyboard_arrow_left,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.parade != null ? "Edit Parade" : "Add Parade"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.navyBlue,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSectionCard(
                title: "Parade Details",
                children: [
                  _fieldLabel("Parade Name"),
                  _textField(
                    controller: _nameController,
                    hint: "Weekly Drill Session",
                    icon: Icons.flag_outlined,
                  ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 16),

                  _fieldLabel("Target Audience"),
                  DropdownButtonFormField<String>(
                    value: _targetYear,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppTheme.accentBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                    items: ['1st Year', '2nd Year', '3rd Year']
                        .map(
                          (label) => DropdownMenuItem(
                            value: label,
                            child: Text(label),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _targetYear = val!),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel("Date"),
                            _textField(
                              controller: _dateController,
                              hint: "YYYY-MM-DD",
                              icon: Icons.calendar_today_outlined,
                              readOnly: true,
                              onTap: () => _selectDate(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel("Time"),
                            _textField(
                              controller: _timeController,
                              hint: "08:00 AM",
                              icon: Icons.access_time_outlined,
                              readOnly: true,
                              onTap: () => _selectTime(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel("Location"),
                  _textField(
                    controller: _locationController,
                    hint: "Main Training Ground",
                    icon: Icons.location_on_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _buildSectionCard(
                title: "Additional Instructions",
                children: [
                  _fieldLabel("Notes (Optional)"),
                  _textField(
                    controller: _descriptionController,
                    hint: "Uniform requirements, equipment, reporting time...",
                    maxLines: 4,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveParade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppTheme.white)
                      : Text(
                          widget.parade != null
                              ? "Update Parade"
                              : "Save & Schedule Parade",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  // ---------------- UI Helpers ----------------

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      validator: (v) =>
          v == null || v.isEmpty ? "This field is required" : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, size: 20, color: AppTheme.accentBlue)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.accentBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
