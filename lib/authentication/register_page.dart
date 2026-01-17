import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/utils/theme.dart';

class RegisterPage extends StatefulWidget {
  final String? initialRole;

  const RegisterPage({super.key, this.initialRole});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // New
  final _roleIdController = TextEditingController();
  final _orgIdController = TextEditingController();

  late String _selectedRole;
  String _selectedYear = '1st Year';
  bool _isLoading = false;
  bool _isObscured = true;
  bool _isConfirmObscured = true; // New

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? 'cadet';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // Dispose
    _roleIdController.dispose();
    _orgIdController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final error = await authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
        roleId: _roleIdController.text.trim(),
        organizationId: _orgIdController.text.trim(),
        year: _selectedYear,
      );

      if (error != null) {
        if (mounted) _showError(error);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registration Successful! Please Login."),
            ),
          );
          Navigator.pop(context); // Go back to Login
        }
      }
    } catch (e) {
      if (mounted) _showError("Registration failed.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only show role selection if no initial role was passed
    final showRoleSelection = widget.initialRole == null;

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left, color: AppTheme.navyBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Image.asset(
                'assets/cadetHublogo.png',
                height: 80,
                width: 80,
                fit: BoxFit.contain,
              ).animate().fade().scale(delay: 100.ms),

              const SizedBox(height: 16),

              Text(
                "Register as ${_selectedRole == 'cadet' ? 'Cadet' : 'Officer'}",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.navyBlue,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fade().slideY(begin: 0.2, end: 0),

              const SizedBox(height: 8),

              Text(
                "Join the National Cadet Corps",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ).animate().fade(delay: 100.ms),

              const SizedBox(height: 32),

              // Form Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Role Selection - Conditionally Visible
                      if (showRoleSelection) ...[
                        Row(
                          children: [
                            Expanded(child: _roleOption('Cadet', 'cadet')),
                            const SizedBox(width: 12),
                            Expanded(child: _roleOption('Officer', 'officer')),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Full Name",
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? "Name is required" : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "Email Address",
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? "Email is required" : null,
                      ),
                      const SizedBox(height: 16),

                      if (_selectedRole == 'cadet') ...[
                        TextFormField(
                          controller: _roleIdController,
                          decoration: const InputDecoration(
                            labelText: "Cadet ID",
                            helperText:
                                'note: you can get this from your unit head',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? "ID is required" : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextFormField(
                        controller: _orgIdController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: "Organization / Unit Code",
                          prefixIcon: Icon(Icons.business_outlined),
                          helperText: _selectedRole == 'cadet'
                              ? 'note: you can get this from your unit head'
                              : null,
                        ),
                        validator: (v) =>
                            v!.isEmpty ? "Org Code is required" : null,
                      ),
                      const SizedBox(height: 16),

                      if (_selectedRole == 'cadet') ...[
                        DropdownButtonFormField<String>(
                          value: _selectedYear,
                          decoration: const InputDecoration(
                            labelText: "Year of Course",
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                          items: ['1st Year', '2nd Year', '3rd Year']
                              .map(
                                (label) => DropdownMenuItem(
                                  value: label,
                                  child: Text(label),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedYear = val!),
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isObscured,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () =>
                                setState(() => _isObscured = !_isObscured),
                          ),
                        ),
                        validator: (v) => v!.length < 6 ? "Min 6 chars" : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _isConfirmObscured,
                        decoration: InputDecoration(
                          labelText: "Confirm Password",
                          prefixIcon: const Icon(Icons.lock_clock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _isConfirmObscured = !_isConfirmObscured,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v!.isEmpty) return "Confirm Password is required";
                          if (v != _passwordController.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text("REGISTER"),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fade(delay: 200.ms).slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleOption(String label, String value) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.navyBlue : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.navyBlue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
