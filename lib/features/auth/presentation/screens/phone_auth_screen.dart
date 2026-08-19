import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:queue_token_app/core/theme/app_colors.dart';
import 'package:queue_token_app/core/widgets/custom_button.dart';
import 'package:queue_token_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:queue_token_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:queue_token_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:queue_token_app/features/auth/presentation/screens/app_root_router.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  bool _isSignUp = false;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onEmailSubmit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in email and password.')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Password must be at least 6 characters long.'),
          backgroundColor: AppColors.warningUrgent,
        ),
      );
      return;
    }

    if (_isSignUp) {
      context.read<AuthBloc>().add(
            AuthSignUpWithEmailRequested(
              email: email,
              password: password,
              name: name.isEmpty ? email.split('@').first : name,
              role: 'customer',
            ),
          );
    } else {
      context.read<AuthBloc>().add(
            AuthSignInWithEmailRequested(
              email: email,
              password: password,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => AppRootRouter(user: state.user),
              ),
            );
          } else if (state is AuthFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.warningUrgent,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Brand Blue Rounded-Square Badge
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '#',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Q-Token System',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkText : AppColors.neutralDark,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Real-time queue tracking',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.neutralMid,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Sign In Title
                      Text(
                        _isSignUp ? 'Create account' : 'Sign in',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkText : AppColors.neutralDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isSignUp
                            ? 'Register as customer to track queues.'
                            : 'Access your dashboard or queue.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.neutralMid,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // In-Line Error Alert Banner
                      if (state is AuthFailureState) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.warningUrgent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warningUrgent.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.warningUrgent, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  state.message,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.warningUrgent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // EMAIL AUTH FORM
                      if (_isSignUp) ...[
                        _buildLabel('Full name', isDark),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _nameController,
                          hintText: 'Alex Rivers',
                          icon: Icons.person_outline_rounded,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                      ],

                      _buildLabel('Email address', isDark),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'admin@queuetoken.app',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Password', isDark),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _passwordController,
                        hintText: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        isDark: isDark,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF9CA3AF),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Primary Action Button (Solid Blue)
                      CustomButton(
                        label: _isSignUp ? 'Sign up' : 'Sign in',
                        onPressed: _onEmailSubmit,
                        isLoading: isLoading,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),

                      // Switch Sign In / Sign Up Footer
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.neutralMid,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _isSignUp = !_isSignUp),
                              child: Text(
                                _isSignUp ? 'Sign in' : 'Sign up',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkText : const Color(0xFF6B7280),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkText : AppColors.neutralDark,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF9CA3AF),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? AppColors.darkBackground : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
