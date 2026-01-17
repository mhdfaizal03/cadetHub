import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:ncc_cadet/authentication/cadet_pending_screen.dart';
import 'package:ncc_cadet/authentication/register_page.dart';
import 'package:ncc_cadet/authentication/forgot_password_page.dart';
import 'package:ncc_cadet/services/auth_service.dart';
import 'package:ncc_cadet/models/user_model.dart';
import 'package:ncc_cadet/providers/user_provider.dart';
import 'package:ncc_cadet/role_navigation.dart';
import 'package:ncc_cadet/utils/theme.dart';

class LoginPage extends StatefulWidget {
  final String? initialRole; // New parameter

  const LoginPage({super.key, this.initialRole});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late String _selectedRole; // Removed initialization here
  bool _isLoading = false;
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    // Use passed role or default to 'cadet'
    _selectedRole = widget.initialRole ?? 'cadet';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();

      // Attempt Login
      final error = await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (error != null) {
        _showError(error);
      } else {
        // Success: Fetch Profile
        final userModel = await authService.getUserProfile();

        if (!mounted) return;

        if (userModel != null) {
          // Validate Role Match
          if (userModel.role != _selectedRole) {
            await authService.logout();
            _showError(
              "Account exists but not as a ${_selectedRole.toUpperCase()}",
            );
          } else {
            // Update Provider
            Provider.of<UserProvider>(
              context,
              listen: false,
            ).setUser(userModel);

            // Access Control
            if (userModel.role == 'cadet') {
              if (userModel.status == 0) {
                _navigate(const CadetPendingPage());
              } else if (userModel.status == -1) {
                await authService.logout();
                _showError("Your registration was rejected.");
              } else {
                navigateByRole(context, 'cadet');
              }
            } else {
              navigateByRole(context, userModel.role);
            }
          }
        } else {
          _showError("User profile not found.");
          await authService.logout();
        }
      }
    } catch (e) {
      _showError("An unexpected error occurred.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigate(Widget page) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we should show the toggle
    // Only show if no specific role was passed
    final showRoleToggle = widget.initialRole == null;

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: widget.initialRole != null
            ? IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_left,
                  color: AppTheme.navyBlue,
                ),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              Image.asset(
                'assets/cadetHublogo.png',
                height: 100,
                width: 100,
                fit: BoxFit.contain,
              ).animate().scale(duration: 400.ms),
              const SizedBox(height: 16),
              Text(
                "Welcome Back",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.navyBlue,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fade().slideY(begin: 0.2, end: 0),

              const SizedBox(height: 32),

              // Role Switcher - Conditionally Visible
              if (showRoleToggle) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    children: [
                      _roleTab("Cadet", 'cadet'),
                      _roleTab("Officer", 'officer'),
                    ],
                  ),
                ).animate().fade(delay: 200.ms),
                const SizedBox(height: 32),
              ],

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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Login as ${_selectedRole == 'cadet' ? 'Cadet' : 'Officer'}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.navyBlue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

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

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: AppTheme.navyBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text("LOGIN"),
                      ),
                    ],
                  ),
                ),
              ).animate().fade(delay: 300.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.black54),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RegisterPage(initialRole: _selectedRole),
                      ),
                    ),
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: AppTheme.navyBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ).animate().fade(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleTab(String label, String roleValue) {
    final isSelected = _selectedRole == roleValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = roleValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? AppTheme.navyBlue : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
