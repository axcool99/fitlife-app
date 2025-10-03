import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ui/components/components.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  // Login function
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Navigate to home on success
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        default:
          errorMessage = 'Login failed: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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

  // Forgot password function
  Future<void> _forgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email first')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Layout Adaptation Strategy:
    // - Use fixed layout that fits standard mobile screens without scrolling
    // - Consistent spacing with RegisterScreen for unified experience
    // - Hint text made more subtle with smaller font size (12px) and reduced opacity (0.5)
    // - Error messages use helperText reservation to prevent layout shifts
    //
    // Spacing Optimizations:
    // - Logo: Fixed width 120px, balanced spacingM (16px) above and below
    // - Logo to title: spacingM (16px) for consistent visual gap
    // - Input fields: spacingS (8px) for compact form layout
    // - Last input to button: spacingXS (4px) for closer proximity
    // - Input contentPadding: spacingS (8px) vertical for compact inputs
    // - Button padding: 12px vertical for proportional smaller buttons

    return Scaffold(
      backgroundColor: FitLifeTheme.background,
      // Enable resizeToAvoidBottomInset to handle keyboard overlap properly
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FitLifeTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo - Fixed size for consistency across screens
              // Width: 120px (fixed), Height: auto (maintains aspect ratio)
              // Balanced spacing: spacingM above and below for visual centering
              const SizedBox(height: FitLifeTheme.spacingXXXL),
              Image.asset(
                'fitlife-logo.jpg',
                width: 120, // Fixed width for consistent sizing across screens
                fit: BoxFit.contain, // Maintains aspect ratio
              ),
              const SizedBox(height: FitLifeTheme.spacingXXXL), // Balanced spacing below logo

              // Title
              AppText(
                'Login to your Account',
                type: AppTextType.headingMedium,
                color: FitLifeTheme.primaryText,
                useCleanStyle: true,
              ),
              const SizedBox(height: FitLifeTheme.spacingS),

              // Subtitle
              AppText(
                'Welcome back! Please sign in to continue',
                type: AppTextType.bodyMedium,
                color: FitLifeTheme.primaryText.withOpacity(0.8),
                useCleanStyle: true,
              ),
              const SizedBox(height: FitLifeTheme.spacingM),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
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
                    const SizedBox(height: FitLifeTheme.spacingS), // Consistent spacing with RegisterScreen

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
                    const SizedBox(height: FitLifeTheme.spacingXS), // Consistent spacing with RegisterScreen

                    // Sign in button
                    if (_isLoading)
                      CircularProgressIndicator(
                        color: FitLifeTheme.accentGray,
                      )
                    else
                      AppButton(
                        text: 'Sign in',
                        variant: AppButtonVariant.primary,
                        onPressed: _login,
                        isLoading: _isLoading,
                        useCleanStyle: true,
                      ),

                    const SizedBox(height: FitLifeTheme.spacingM),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: FitLifeTheme.borderColor,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: FitLifeTheme.spacingM),
                          child: AppText(
                            'Or sign in with',
                            type: AppTextType.bodySmall,
                            color: FitLifeTheme.primaryText.withOpacity(0.8),
                            useCleanStyle: true,
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: FitLifeTheme.borderColor,
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
                            // TODO: Implement Google sign in
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Google sign in coming soon')),
                            );
                          },
                          useCleanStyle: true,
                        ),
                        const SizedBox(width: FitLifeTheme.spacingM),

                        // Facebook button
                        SocialButton(
                          icon: Icons.facebook,
                          onPressed: () {
                            // TODO: Implement Facebook sign in
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Facebook sign in coming soon')),
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

                    const SizedBox(height: FitLifeTheme.spacingL),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(
                          "Don't have an account?",
                          type: AppTextType.bodyMedium,
                          color: FitLifeTheme.textSecondary,
                          useCleanStyle: true,
                        ),
                        const SizedBox(width: FitLifeTheme.spacingXS),
                        GestureDetector(
                          onTap: () {
                            // Navigate to register screen
                            Navigator.pushReplacementNamed(context, '/register');
                          },
                          child: AppText(
                            'Sign up',
                            type: AppTextType.bodyMedium,
                            color: FitLifeTheme.accentGray,
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
      ),
    );
  }
}