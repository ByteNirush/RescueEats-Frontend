import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rescueeats/core/utils/responsive_utils.dart';
import 'package:rescueeats/features/routes/routeconstants.dart';
import 'package:rescueeats/screens/auth/provider/authprovider.dart';
import 'package:rescueeats/screens/auth/provider/authstate.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        constraints: BoxConstraints(
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
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: context.text.h1,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: context.spacing.small),
                      Text(
                        'Log into your existing Account',
                        style: TextStyle(
                          fontSize: context.text.bodyMedium,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: context.spacing.large),

                      TextFormField(
                        controller: _emailController,
                        enabled: !isLoading,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Email or Phone Number',
                          hintStyle: TextStyle(
                            color: Colors.black54,
                            fontSize: context.text.bodyMedium,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: context.padding.medium,
                            vertical: context.isMobile ? 16 : 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Colors.black26,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Colors.black26,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF6B00),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: context.spacing.medium),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        enabled: !isLoading,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(
                            color: Colors.black54,
                            fontSize: context.text.bodyMedium,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: context.padding.medium,
                            vertical: context.isMobile ? 16 : 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Colors.black26,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Colors.black26,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF6B00),
                              width: 2,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: context.spacing.small),

                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  // Navigate to Forgot Password
                                  context.push(RouteConstants.forgotPassword);
                                },
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: context.text.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: context.spacing.medium),

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
                                        .login(
                                          emailOrPhone: _emailController.text
                                              .trim(),
                                          password: _passwordController.text
                                              .trim(),
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
                          child: Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: context.text.bodyMedium,
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
                          Text(
                            "Don't have an Account? ",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: context.text.bodyMedium,
                            ),
                          ),
                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () {
                                    context.go(RouteConstants.register);
                                  },
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: context.text.bodyMedium,
                                fontWeight: FontWeight.bold,
                              ),
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
}
