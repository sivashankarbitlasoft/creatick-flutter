import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_service.dart';
import '../../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoginMode = true;
  bool _showForgotPassword = false;
  bool _otpSent = false;
  bool _forgotPasswordLoading = false;
  bool _loginPasswordVisible = false;
  bool _signupPasswordVisible = false;
  bool _signupConfirmVisible = false;

  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();

  final _signupFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  final _forgotPasswordFormKey = GlobalKey<FormState>();
  final _forgotEmailCtrl = TextEditingController();
  final _otpFormKey = GlobalKey<FormState>();
  final _otpCtrl = TextEditingController();
  final _resetPasswordCtrl = TextEditingController();
  final _resetConfirmPasswordCtrl = TextEditingController();

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _forgotEmailCtrl.dispose();
    _otpCtrl.dispose();
    _resetPasswordCtrl.dispose();
    _resetConfirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Colors.red,
      ),
    );
  }

  // Returns an error message for the given email value, or null when valid.
  String? _emailError(String? value, {bool allowPhone = false}) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final trimmed = value.trim();
    if (allowPhone && !trimmed.contains('@')) {
      // Treat input without '@' as phone number for login flows
      return null;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  void _submitLogin() {
    if (!_loginFormKey.currentState!.validate()) {
      final err = _emailError(_loginEmailCtrl.text, allowPhone: true);
      if (err != null) _showMessage(err);
      return;
    }

    ref.read(authProvider.notifier).login(
      _loginEmailCtrl.text.trim(),
      _loginPasswordCtrl.text,
    );
  }

  void _submitSignup() {
    if (!_signupFormKey.currentState!.validate()) {
      final err = _emailError(_signupEmailCtrl.text);
      if (err != null) _showMessage(err);
      return;
    }

    ref.read(authProvider.notifier).register(
      name: _nameCtrl.text.trim(),
      email: _signupEmailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      password: _signupPasswordCtrl.text,
    );
  }

  Future<void> _submitForgotPasswordRequest() async {
    if (!_forgotPasswordFormKey.currentState!.validate()) {
      final err = _emailError(_forgotEmailCtrl.text);
      if (err != null) _showMessage(err);
      return;
    }

    setState(() => _forgotPasswordLoading = true);
    try {
      await ApiService.forgotPassword(_forgotEmailCtrl.text.trim());
      setState(() {
        _otpSent = true;
        _showForgotPassword = true;
      });
      _showMessage('OTP sent successfully.', color: Colors.green);
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _forgotPasswordLoading = false);
      }
    }
  }

  Future<void> _submitForgotPasswordVerify() async {
    if (!_otpFormKey.currentState!.validate()) return;

    final otp = _otpCtrl.text.trim();
    final password = _resetPasswordCtrl.text;
    final confirmPassword = _resetConfirmPasswordCtrl.text;

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() => _forgotPasswordLoading = true);
    try {
      await ApiService.verifyForgotPassword(
        email: _forgotEmailCtrl.text.trim(),
        otp: otp,
        newPassword: password,
      );

      _showMessage('Password reset successful. Please login.',
          color: Colors.green);
      setState(() {
        _showForgotPassword = false;
        _otpSent = false;
        _isLoginMode = true;
        _forgotEmailCtrl.clear();
        _otpCtrl.clear();
        _resetPasswordCtrl.clear();
        _resetConfirmPasswordCtrl.clear();
      });
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _forgotPasswordLoading = false);
      }
    }
  }

  Widget _buildPhoneMockup({required Widget child}) {
    // Use a full-screen container without rounded corners or shadows so the
    // auth screens occupy the entire device area as requested.
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF4F5FA),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        _showMessage(next.error!);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEF3),
      body: SafeArea(
        child: _buildPhoneMockup(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _showForgotPassword
                ? _buildForgotPasswordScreen()
                : _buildAuthScreenContent(authState),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthScreenContent(AuthState authState) {
    return Column(
      children: [
        const SizedBox(height: 18),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _buildBrandHeader(),
                const SizedBox(height: 22),
                _buildModeToggle(),
                const SizedBox(height: 22),
                if (_isLoginMode) _buildLoginForm() else _buildSignupForm(),
                const SizedBox(height: 10),
                if (_isLoginMode)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _showForgotPassword = true;
                          _otpSent = false;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Color(0xFF4F6BFF),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                _buildPrimaryButton(
                  label: _isLoginMode ? 'Login' : 'Sign Up',
                  onPressed: authState.isLoading
                      ? null
                      : (_isLoginMode ? _submitLogin : _submitSignup),
                  isLoading: authState.isLoading,
                ),
                const SizedBox(height: 28),
                if (_isLoginMode)
                  _buildBottomPrompt(
                    prompt: "Don't have an account?",
                    action: 'Sign Up',
                    onTap: () => setState(() => _isLoginMode = false),
                  )
                else
                  _buildBottomPrompt(
                    prompt: 'Already have an account?',
                    action: 'Login',
                    onTap: () => setState(() => _isLoginMode = true),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordScreen() {
    final showOtpFields = _otpSent;

    // Make the forgot-password screen scrollable so it won't overflow on narrow/short devices.
    return Column(
      children: [
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        _showForgotPassword = false;
                        _otpSent = false;
                        _forgotPasswordLoading = false;
                        _forgotEmailCtrl.clear();
                        _otpCtrl.clear();
                        _resetPasswordCtrl.clear();
                        _resetConfirmPasswordCtrl.clear();
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'Back to Login',
                            style: TextStyle(
                              color: Color(0xFF2B2D42),
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7EEFF),
                    borderRadius: BorderRadius.circular(56),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 56,
                    color: Color(0xFF4F6BFF),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Forgot Password?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E3A59),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    'No worries! Enter your registered email address and reset your password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF7F8AA3),
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: !showOtpFields
                      ? Form(
                          key: _forgotPasswordFormKey,
                          child: _buildAuthTextField(
                            controller: _forgotEmailCtrl,
                            hintText: 'Enter your email address',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              final email = value.trim();
                              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(email)) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                        )
                      : Form(
                          key: _otpFormKey,
                          child: Column(
                            children: [
                              _buildAuthTextField(
                                controller: _otpCtrl,
                                hintText: 'Enter OTP',
                                prefixIcon: Icons.pin_rounded,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'OTP is required';
                                  }
                                  if (!RegExp(r'^\d+$')
                                      .hasMatch(value.trim())) {
                                    return 'OTP must contain only numbers';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildAuthTextField(
                                controller: _resetPasswordCtrl,
                                hintText: 'New password',
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildAuthTextField(
                                controller: _resetConfirmPasswordCtrl,
                                hintText: 'Confirm password',
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _resetPasswordCtrl.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _buildPrimaryButton(
                    label: showOtpFields ? 'Verify OTP' : 'Send Reset Link',
                    onPressed: _forgotPasswordLoading
                        ? null
                        : (showOtpFields
                            ? _submitForgotPasswordVerify
                            : _submitForgotPasswordRequest),
                    isLoading: _forgotPasswordLoading,
                    hasArrow: true,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: const [
                    Expanded(
                        child:
                            Divider(color: Color(0xFFCDD5E7), thickness: 1.2)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Remember your password?',
                        style:
                            TextStyle(color: Color(0xFF7F8AA3), fontSize: 15),
                      ),
                    ),
                    Expanded(
                        child:
                            Divider(color: Color(0xFFCDD5E7), thickness: 1.2)),
                  ],
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showForgotPassword = false;
                      _otpSent = false;
                      _forgotEmailCtrl.clear();
                      _otpCtrl.clear();
                      _resetPasswordCtrl.clear();
                      _resetConfirmPasswordCtrl.clear();
                    });
                  },
                  child: const Text(
                    'Login →',
                    style: TextStyle(
                      color: Color(0xFF4F6BFF),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: const Color(0xFFE9ECFF),
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Icon(
            Icons.confirmation_number_rounded,
            size: 56,
            color: Color(0xFF4F6BFF),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'BA Ticket App',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2E3A59),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _isLoginMode
              ? 'Welcome back! Please login to continue'
              : 'Create your account to get started',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF7F8AA3),
          ),
        ),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E9F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Login',
              selected: _isLoginMode,
              onTap: () => setState(() => _isLoginMode = true),
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'Sign Up',
              selected: !_isLoginMode,
              onTap: () => setState(() => _isLoginMode = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          _buildAuthTextField(
            controller: _loginEmailCtrl,
            hintText: 'Enter your email or phone number',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              final trimmed = value.trim();
              if (trimmed.contains('@')) {
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
                  return 'Enter a valid email address';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _buildAuthTextField(
            controller: _loginPasswordCtrl,
            hintText: 'Enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: !_loginPasswordVisible,
            suffixIcon: _loginPasswordVisible
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            onSuffixTap: () =>
                setState(() => _loginPasswordVisible = !_loginPasswordVisible),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _signupFormKey,
      child: Column(
        children: [
          _buildAuthTextField(
            controller: _nameCtrl,
            hintText: 'Enter your name',
            prefixIcon: Icons.person_outline_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _buildAuthTextField(
            controller: _phoneCtrl,
            hintText: 'Enter your phone number',
            prefixIcon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _buildAuthTextField(
            controller: _signupEmailCtrl,
            hintText: 'Enter your email',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                  .hasMatch(value.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _buildAuthTextField(
            controller: _signupPasswordCtrl,
            hintText: 'Create a password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: !_signupPasswordVisible,
            suffixIcon: _signupPasswordVisible
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            onSuffixTap: () => setState(
                () => _signupPasswordVisible = !_signupPasswordVisible),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _buildAuthTextField(
            controller: _confirmPasswordCtrl,
            hintText: 'Confirm your password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: !_signupConfirmVisible,
            suffixIcon: _signupConfirmVisible
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            onSuffixTap: () =>
                setState(() => _signupConfirmVisible = !_signupConfirmVisible),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _signupPasswordCtrl.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAuthTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 16, color: Color(0xFF2E3A59)),
      validator: validator,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        filled: true,
        fillColor: Colors.transparent,
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFFB5B9C9), fontSize: 16),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF6D7AA8), size: 22),
        suffixIcon: suffixIcon == null
            ? null
            : GestureDetector(
                onTap: onSuffixTap,
                child:
                    Icon(suffixIcon, color: const Color(0xFF6D7AA8), size: 22),
              ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCAD3F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF4F6BFF), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.8),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
    bool hasArrow = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F6BFF),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hasArrow) const SizedBox(width: 8),
                  if (hasArrow)
                    const Icon(Icons.arrow_forward_rounded, size: 26),
                ],
              ),
      ),
    );
  }

  Widget _buildBottomPrompt({
    required String prompt,
    required String action,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          prompt,
          style: const TextStyle(
            color: Color(0xFF6E7A95),
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onTap,
          child: Text(
            '$action →',
            style: const TextStyle(
              color: Color(0xFF4F6BFF),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4F6BFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6E7A95),
            fontSize: 18,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
