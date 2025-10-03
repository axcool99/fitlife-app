import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ui/components/components.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Name validation
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  // Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  // Password validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Confirm password validation
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Register function
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Navigate to home on success
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists for that email.';
          break;
        default:
          errorMessage = 'Registration failed: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Layout Adaptation Strategy:
    // - Use LayoutBuilder with ConstrainedBox to ensure content fits within available screen space
    // - SingleChildScrollView with NeverScrollableScrollPhysics prevents scrolling but allows content to be measured
    // - mainAxisSize: MainAxisSize.min on Columns allows content to shrink to fit available space
    // - Fixed logo size (120px width) and balanced spacing to fit all content without overflow
    // - Maintain consistent input field sizes and spacing with LoginScreen
    // - Ensure social buttons and footer are always visible without requiring scroll
    // - Error messages use helperText reservation to prevent layout shifts
    //
    // Spacing Optimizations:
    // - Logo: Fixed width 120px, balanced spacingM (16px) above and below
    // - Logo to title: spacingM (16px) for consistent visual gap with LoginScreen
    // - Title to subtitle: spacingXS (4px) for tighter spacing
    // - Subtitle to form: spacingS (8px) for tighter spacing
    // - Input fields: spacingS (8px) for compact form layout
    // - Last input to button: spacingXS (4px) for closer proximity
    // - Button to divider: spacingS (8px) for tighter spacing
    // - Divider to social buttons: spacingS (8px) for tighter spacing
    // - Social buttons to footer: spacingS (8px) for tighter spacing
    // - Input contentPadding: spacingS (8px) vertical for compact inputs
    // - Button padding: 12px vertical for proportional smaller buttons

    return Scaffold(
      backgroundColor: FitLifeTheme.background,
      // Enable resizeToAvoidBottomInset to handle keyboard overlap properly
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FitLifeTheme.spacingL),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo - Fixed size for consistency across screens
                      // Width: 120px (fixed), Height: auto (maintains aspect ratio)
                      // Balanced spacing: spacingM above and below for visual centering
                      // Removed extra padding that was compensating for old logo whitespace
                      const SizedBox(height: FitLifeTheme.spacingXXXL),
                      Image.asset(
                        'fitlife-logo.jpg',
                        width: 120, // Fixed width for consistent sizing across screens
                        fit: BoxFit.contain, // Maintains aspect ratio
                      ),
                      const SizedBox(height: FitLifeTheme.spacingXXXL), // Balanced spacing below logo                      // Title
                      AppText(
                        'Create your Account',
                        type: AppTextType.headingMedium,
                        color: FitLifeTheme.primaryText,
                        useCleanStyle: true,
                      ),
                      const SizedBox(height: FitLifeTheme.spacingXS), // Reduced from spacingS for tighter spacing

                      // Subtitle
                      AppText(
                        'Join us and start your fitness journey',
                        type: AppTextType.bodyMedium,
                        color: FitLifeTheme.primaryText.withOpacity(0.8),
                        useCleanStyle: true,
                      ),
                      const SizedBox(height: FitLifeTheme.spacingM),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Name field
                            AppInput(
                              controller: _nameController,
                              hintText: 'Enter your full name',
                              labelText: 'Full Name',
                              prefixIcon: Icons.person,
                              validator: _validateName,
                              useCleanStyle: true,
                            ),
                            const SizedBox(height: FitLifeTheme.spacingS), // Consistent spacing with LoginScreen

                            // Email field
                            AppInput(
                              controller: _emailController,
                              hintText: 'Enter your email',
                              labelText: 'Email',
                              prefixIcon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                              useCleanStyle: true,
                            ),
                            const SizedBox(height: FitLifeTheme.spacingS), // Consistent spacing with LoginScreen

                            // Password field
                            AppInput(
                              controller: _passwordController,
                              hintText: 'Enter your password',
                              labelText: 'Password',
                              prefixIcon: Icons.lock,
                              isPassword: true,
                              validator: _validatePassword,
                              useCleanStyle: true,
                            ),
                            const SizedBox(height: FitLifeTheme.spacingS), // Consistent spacing with LoginScreen

                            // Confirm Password field
                            AppInput(
                              controller: _confirmPasswordController,
                              hintText: 'Confirm your password',
                              labelText: 'Confirm Password',
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                              validator: _validateConfirmPassword,
                              useCleanStyle: true,
                            ),
                            const SizedBox(height: FitLifeTheme.spacingXS), // Consistent spacing with LoginScreen

                            // Sign up button
                            if (_isLoading)
                              CircularProgressIndicator(
                                color: FitLifeTheme.accentGreen,
                              )
                            else
                              AppButton(
                                text: 'Sign up',
                                variant: AppButtonVariant.primary,
                                onPressed: _register,
                                isLoading: _isLoading,
                                useCleanStyle: true,
                              ),

                            const SizedBox(height: FitLifeTheme.spacingM),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: FitLifeTheme.dividerColor,
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: FitLifeTheme.spacingM),
                                  child: AppText(
                                    'Or sign up with',
                                    type: AppTextType.bodySmall,
                                    color: FitLifeTheme.primaryText.withOpacity(0.8),
                                    useCleanStyle: true,
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: FitLifeTheme.dividerColor,
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: FitLifeTheme.spacingM),

                            // Social login buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google button
                                SocialButton(
                                  icon: Icons.g_mobiledata,
                                  onPressed: () {
                                    // TODO: Implement Google sign up
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Google sign up coming soon')),
                                    );
                                  },
                                  useCleanStyle: true,
                                ),
                                const SizedBox(width: FitLifeTheme.spacingM),

                                // Facebook button
                                SocialButton(
                                  icon: Icons.facebook,
                                  onPressed: () {
                                    // TODO: Implement Facebook sign up
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Facebook sign up coming soon')),
                                    );
                                  },
                                  useCleanStyle: true,
                                ),
                                const SizedBox(width: FitLifeTheme.spacingM),

                                // Apple button
                                SocialButton(
                                  icon: Icons.apple, // Apple sign in icon
                                  onPressed: () {
                                    // TODO: Implement Apple sign in
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Apple sign in coming soon')),
                                    );
                                  },
                                  useCleanStyle: true,
                                ),
                              ],
                            ),

                            const SizedBox(height: FitLifeTheme.spacingM),

                            // Footer - Always visible without scrolling
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppText(
                                  "Already have an account?",
                                  type: AppTextType.bodyMedium,
                                  color: FitLifeTheme.primaryText.withOpacity(0.8),
                                  useCleanStyle: true,
                                ),
                                const SizedBox(width: FitLifeTheme.spacingXS),
                                GestureDetector(
                                  onTap: () {
                                    // Navigate to login screen
                                    Navigator.pushReplacementNamed(context, '/login');
                                  },
                                  child: AppText(
                                    'Sign in',
                                    type: AppTextType.bodyMedium,
                                    color: FitLifeTheme.accentGreen,
                                    useCleanStyle: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
