// lib/screens/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _selectedRole = AppConstants.roleUser;
  
  // Password criteria states
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;

  // Validation UI states
  bool _emailTouched = false;
  bool _isEmailValid = true;
  bool _passwordTouched = false;
  bool _isPasswordValid = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _passwordController.addListener(_validatePassword);
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
            role: _selectedRole,
            phone: _phoneController.text.trim(),
          );
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: AppTheme.backgroundColor),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ── Hero Header ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => context.go('/login'),
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white),
                        ),
                      ),
                      Text(
                        'Create Account 🍱',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Join Mess Finder and discover great food',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Form ──
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Role selector
                          Text(
                            'I am a...',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _RoleChip(
                                  emoji: '🧑',
                                  label: 'User',
                                  subtitle: 'Find & order food',
                                  value: AppConstants.roleUser,
                                  selected: _selectedRole,
                                  onTap: () => setState(
                                      () => _selectedRole = AppConstants.roleUser),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _RoleChip(
                                  emoji: '🏠',
                                  label: 'Mess Owner',
                                  subtitle: 'Manage your mess',
                                  value: AppConstants.roleOwner,
                                  selected: _selectedRole,
                                  onTap: () => setState(
                                      () => _selectedRole = AppConstants.roleOwner),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          _buildField('Full Name', _nameController,
                              icon: Icons.person_outlined, hint: 'John Doe'),
                          const SizedBox(height: 16),
                          _buildField('Email', _emailController,
                              icon: Icons.email_outlined,
                              hint: 'you@gmail.com',
                              keyboard: TextInputType.emailAddress,
                              hasError: !_isEmailValid && _emailTouched,
                              validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter your email';
                            if (!v.contains('@')) return 'Enter a valid email';
                            if (!v.trim().toLowerCase().endsWith('@gmail.com')) {
                              return 'Only Gmail addresses are allowed';
                            }
                            return null;
                          }),
                          const SizedBox(height: 16),
                          _buildField('Phone Number', _phoneController,
                              icon: Icons.phone_outlined,
                              hint: '+91 9999999999',
                              keyboard: TextInputType.phone,
                              required: false),
                          const SizedBox(height: 16),

                          // Password
                          Text(
                            'Password',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: Icon(Icons.lock_outlined,
                                  color: AppTheme.textLight, size: 20),
                              enabledBorder: (!_isPasswordValid && _passwordTouched)
                                  ? OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                    )
                                  : null,
                              focusedBorder: (!_isPasswordValid && _passwordTouched)
                                  ? OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                                    )
                                  : null,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppTheme.textLight,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter a password';
                              if (!_hasMinLength || !_hasUppercase || !_hasLowercase || !_hasDigit || !_hasSpecialChar) {
                                return 'Password does not meet all criteria';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 12),
                          _buildCriteriaChecklist(),

                          const SizedBox(height: 28),

                          // Signup button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.primaryShadow,
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      'Create Account',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          
                          // OR Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'OR',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Google Sign Up Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : () async {
                                setState(() => _isLoading = true);
                                try {
                                  // Google sign in creates the account automatically if it doesn't exist
                                  await ref.read(authProvider.notifier).signInWithGoogle();
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor: Colors.redAccent,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => _isLoading = false);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                              ),
                              icon: Image.network(
                                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                                height: 24,
                              ),
                              label: Text(
                                'Continue with Google',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/login'),
                                child: Text(
                                  'Sign In',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    String? hint,
    TextInputType keyboard = TextInputType.text,
    bool required = true,
    bool hasError = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon, color: AppTheme.textLight, size: 20)
                : null,
            enabledBorder: hasError 
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                  )
                : null,
            focusedBorder: hasError 
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                  )
                : null,
          ),
          validator: validator ??
              (required
                  ? (v) =>
                      (v == null || v.isEmpty) ? 'This field is required' : null
                  : null),
        ),
      ],
    );
  }

  void _validateEmail() {
    final email = _emailController.text;
    if (email.isEmpty) {
      setState(() {
        _isEmailValid = true;
      });
      return;
    }
    setState(() {
      _emailTouched = true;
      _isEmailValid = email.contains('@') && email.trim().toLowerCase().endsWith('@gmail.com');
    });
  }

  void _validatePassword() {
    final pass = _passwordController.text;
    if (pass.isEmpty) {
      setState(() {
        _hasMinLength = false;
        _hasUppercase = false;
        _hasLowercase = false;
        _hasDigit = false;
        _hasSpecialChar = false;
        _isPasswordValid = true;
      });
      return;
    }
    setState(() {
      _passwordTouched = true;
      _hasMinLength = pass.length >= 8;
      _hasUppercase = pass.contains(RegExp(r'[A-Z]'));
      _hasLowercase = pass.contains(RegExp(r'[a-z]'));
      _hasDigit = pass.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _isPasswordValid = _hasMinLength && _hasUppercase && _hasLowercase && _hasDigit && _hasSpecialChar;
    });
  }

  Widget _buildCriteriaChecklist() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements:',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildCriteriaItem('At least 8 characters', _hasMinLength),
          _buildCriteriaItem('At least one uppercase letter', _hasUppercase),
          _buildCriteriaItem('At least one lowercase letter', _hasLowercase),
          _buildCriteriaItem('At least one number', _hasDigit),
          _buildCriteriaItem('At least one special character (!@#\$%^&*)', _hasSpecialChar),
        ],
      ),
    );
  }

  Widget _buildCriteriaItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isMet ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isMet ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String emoji, label, subtitle, value, selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppTheme.softShadow : [],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
