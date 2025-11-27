import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescueeats/core/model/userModel.dart';
import 'package:rescueeats/core/utils/responsive_utils.dart';
import 'package:rescueeats/features/routes/routeconstants.dart';
import 'package:rescueeats/screens/auth/provider/authprovider.dart';
import 'package:rescueeats/screens/auth/provider/authstate.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  UserRole _selectedRole = UserRole.user;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch auth state
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    // 2. Wrap in Stack
    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.padding.horizontal,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: context.spacing.large),
                      Container(
                        height: context.isShortScreen
                            ? context.heightPercent(25)
                            : context.heightPercent(30),
                        constraints: const BoxConstraints(
                          maxHeight: 280,
                          minHeight: 180,
                        ),
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                              'assets/images/delivery_scooter.png',
                            ),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: context.spacing.medium),
                      Text(
                        "Let's Get Started",
                        style: TextStyle(
                          fontSize: context.text.h1,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: context.spacing.small),
                      Text(
                        'Create an Account',
                        style: TextStyle(
                          fontSize: context.text.bodyMedium,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: context.spacing.medium),

                      // Role Selector
                      IgnorePointer(
                        // Prevents changing role while loading
                        ignoring: isLoading,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black26,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<UserRole>(
                              value: _selectedRole,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFFFF6B00),
                              ),
                              items: UserRole.values.map((UserRole role) {
                                return DropdownMenuItem<UserRole>(
                                  value: role,
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getRoleIcon(role),
                                        color: Colors.black54,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        _getRoleName(role),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (UserRole? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedRole = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: context.spacing.medium),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Name',
                        enabled: !isLoading,
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        hint: 'Email',
                        enabled: !isLoading,
                        validator: (val) => val == null || !val.contains('@')
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        hint: 'Phone Number',
                        isPhone: true,
                        enabled: !isLoading,
                        validator: (val) => val == null || val.length < 10
                            ? 'Enter valid phone number'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        hint: 'Password',
                        isPassword: true,
                        enabled: !isLoading,
                        validator: (val) => val == null || val.length < 6
                            ? 'Password must be 6+ chars'
                            : null,
                      ),

                      SizedBox(height: context.spacing.large),

                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        height: context.sizes.buttonHeight,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    ref
                                        .read(authProvider.notifier)
                                        .register(
                                          name: _nameController.text.trim(),
                                          email: _emailController.text.trim(),
                                          phoneNumber: _phoneController.text
                                              .trim(),
                                          password: _passwordController.text
                                              .trim(),
                                          role: _selectedRole,
                                        );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B00),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'SIGN UP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: context.spacing.medium),

                      // OR Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: Colors.black26, thickness: 1),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.padding.medium,
                            ),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: context.text.bodyMedium,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: Colors.black26, thickness: 1),
                          ),
                        ],
                      ),
                      SizedBox(height: context.spacing.medium),

                      // Google Sign-In disabled - not supported by backend
                      SizedBox(
                        width: double.infinity,
                        height: context.sizes.buttonHeight,
                        child: OutlinedButton.icon(
                          onPressed: null, // Disabled until backend supports it
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.black12, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            backgroundColor: Colors.grey[100],
                          ),
                          icon: Image.asset(
                            'assets/icons/google_icon.png',
                            height: 24,
                            width: 24,
                            color: Colors.grey,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.g_mobiledata,
                                color: Colors.grey,
                                size: 28,
                              );
                            },
                          ),
                          label: Text(
                            'Google Sign-In (Coming Soon)',
                            style: TextStyle(
                              fontSize: context.text.bodyMedium,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: context.spacing.medium),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an Account? '),
                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () => context.go(RouteConstants.login),
                            child: const Text(
                              'Login',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.spacing.large),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // 3. Loading Overlay
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
            ),
          ),
      ],
    );
  }

  // Updated Helper widget to accept enabled state
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    bool isPhone = false,
    bool enabled = true, // Added this
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : false,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      validator: validator,
      enabled: enabled, // Apply it here
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54, fontSize: 16),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        // ... Borders (Keep existing border code)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.black26, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.black26, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFFF6B00), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
      ),
    );
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.restaurant:
        return 'Restaurant Partner';
      case UserRole.delivery:
        return 'Delivery Partner';
      case UserRole.admin:
        return 'Admin';
      case UserRole.user:
        return 'Customer';
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.restaurant:
        return Icons.store;
      case UserRole.delivery:
        return Icons.delivery_dining;
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.user:
        return Icons.person;
    }
  }
}
