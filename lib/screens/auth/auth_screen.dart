import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoginMode = true;

  // Login form
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();

  // Sign-up form
  final _signupFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_loginFormKey.currentState!.validate()) {
      ref.read(authProvider.notifier).login(
            _loginEmailCtrl.text.trim(),
            _loginPasswordCtrl.text,
          );
    }
  }

  void _submitSignup() {
    // Form validators (below) already check the passwords match,
    // but this keeps the intent explicit and safe against future edits.
    if (_signupFormKey.currentState!.validate()) {
      ref.read(authProvider.notifier).register(
            name: _nameCtrl.text.trim(),
            email: _signupEmailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            password: _signupPasswordCtrl.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Show a one-time error message if login/signup failed.
    ref.listen(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Icon(Icons.confirmation_number_outlined,
                    size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  'BA Ticket App',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                _buildModeToggle(),
                const SizedBox(height: 24),
                if (_isLoginMode) _buildLoginForm() else _buildSignupForm(),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: authState.isLoading
                      ? null
                      : (_isLoginMode ? _submitLogin : _submitSignup),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isLoginMode ? 'Login' : 'Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Row(
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
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _loginEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Email is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _loginPasswordCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Password is required' : null,
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
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _signupEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Email is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _signupPasswordCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
            validator: (v) => (v == null || v.length < 6)
                ? 'Password must be at least 6 characters'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmPasswordCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm password'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _signupPasswordCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
        ],
      ),
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
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? color : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? color : Colors.grey,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
